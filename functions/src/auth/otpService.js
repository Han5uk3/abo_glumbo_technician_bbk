"use strict";

// requestOtp and verifyOtp logic. Dependencies are injected so the whole flow
// can be tested against an in-memory database without any network.

const { Timestamp } = require("firebase-admin/firestore");
const { otpError } = require("./errors");
const {
  DAY_MS,
  GLOBAL_COUNTER_SHARDS,
  HOUR_MS,
  OTP_TTL_MS,
  PHONE_CHANGES_PER_DAY,
  PHONE_LIMITS,
  PURPOSE_CHANGE_PHONE,
  PURPOSE_LOGIN,
  REMINT_WINDOW_MS,
  STATE_TTL_MS,
  VERIFICATION_PREFIX,
  challengeHmac,
  checkPhoneSend,
  checkWindow,
  clientIp,
  decideVerification,
  generateCode,
  isReserved,
  isSaudiMobile,
  maskPhone,
  newChallengeId,
  nextReservedGuard,
  normalizeLocale,
  refundPhoneSend,
  reservedCodeHmac,
  resolveApp,
  smsBody,
  stateKey,
} = require("./otpCore");

const CHALLENGE_ID = /^[0-9a-f]{32}$/;
const OTP_CODE = /^\d{6}$/;
const REQUEST_ID = /^[A-Za-z0-9_-]{8,64}$/;

function parseRequestInput(data, attestedAppId) {
  const phone = typeof data?.phone === "string" ? data.phone.trim() : "";
  if (!isSaudiMobile(phone)) throw otpError("invalid-phone-number");
  const purpose = data?.purpose ?? PURPOSE_LOGIN;
  if (purpose !== PURPOSE_LOGIN && purpose !== PURPOSE_CHANGE_PHONE) {
    throw otpError("internal-error");
  }
  return {
    phone,
    purpose,
    locale: normalizeLocale(data?.locale),
    app: resolveApp(attestedAppId, data?.app),
    expectedUid: typeof data?.expectedUid === "string" ? data.expectedUid : null,
  };
}

function parseVerifyInput(data) {
  const verificationId = typeof data?.verificationId === "string" ? data.verificationId : "";
  const challengeId = verificationId.startsWith(VERIFICATION_PREFIX)
    ? verificationId.slice(VERIFICATION_PREFIX.length)
    : "";
  const code = typeof data?.code === "string" ? data.code : "";
  const requestId = typeof data?.requestId === "string" ? data.requestId : "";
  if (!CHALLENGE_ID.test(challengeId)) throw otpError("session-expired");
  if (!OTP_CODE.test(code)) throw otpError("invalid-verification-code");
  if (!REQUEST_ID.test(requestId)) throw otpError("internal-error");
  return {
    challengeId,
    code,
    requestId,
    expectedUid: typeof data?.expectedUid === "string" ? data.expectedUid : null,
  };
}

function createOtpService({
  otpDb,
  auth,
  phoneChange,
  sendSms,
  getConfig,
  logger,
  now = Date.now,
  random = Math.random,
}) {
  const collection = (name) => otpDb.collection(name);
  const expireAt = (nowMs) => Timestamp.fromMillis(nowMs + STATE_TTL_MS);

  function logAppCheck(fn, request) {
    // Monitor mode: enforcement stays off until real builds are seen to pass.
    logger.info("otp_app_check", { fn, attested: Boolean(request.app) });
  }

  function counterRef(nowMs, attested) {
    const hour = Math.floor(nowMs / HOUR_MS);
    const shard = Math.floor(random() * GLOBAL_COUNTER_SHARDS);
    return collection("counters").doc(`${hour}_${attested ? "a" : "u"}_${shard}`);
  }

  async function reserveSend({ input, session, reserved, attested, ip, code, config }) {
    const nowMs = now();
    const challengeId = newChallengeId();
    const { phone, purpose } = input;
    const uid = session?.uid ?? null;

    const challengeRef = collection("challenges").doc(challengeId);
    const phoneRef = collection("phones").doc(stateKey(config.pepper, "phone", phone));
    const ipRef = collection("ips").doc(stateKey(config.pepper, "ip", ip));
    const globalRef = counterRef(nowMs, attested);
    const uidRef = uid ? collection("uids").doc(uid) : null;

    const globalLimit = attested ? config.limits.globalHourly : config.limits.unattestedHourly;
    const shardLimit = Math.max(1, Math.ceil(globalLimit / GLOBAL_COUNTER_SHARDS));

    const outcome = await otpDb.runTransaction(async (tx) => {
      const [phoneSnap, ipSnap, globalSnap, uidSnap] = await Promise.all([
        tx.get(phoneRef),
        tx.get(ipRef),
        tx.get(globalRef),
        uidRef ? tx.get(uidRef) : Promise.resolve(null),
      ]);

      const ipCheck = checkWindow(ipSnap.data(), nowMs, HOUR_MS, config.limits.ipHourly);
      if (!ipCheck.allowed) return { blocked: "ip", ...ipCheck };

      // A reserved number sends no SMS, so it spends no budget. Skipping these
      // limits also stops anyone from locking a core admin out by spamming it.
      let phoneCheck = null;
      let globalCheck = null;
      let uidCheck = null;
      if (!reserved) {
        phoneCheck = checkPhoneSend(phoneSnap.data(), nowMs, PHONE_LIMITS);
        if (!phoneCheck.allowed) return { blocked: "phone", ...phoneCheck };
        globalCheck = checkWindow(globalSnap.data(), nowMs, HOUR_MS, shardLimit);
        if (!globalCheck.allowed) return { blocked: "global", ...globalCheck };
        if (uidRef) {
          uidCheck = checkWindow(uidSnap.data(), nowMs, DAY_MS, PHONE_CHANGES_PER_DAY);
          if (!uidCheck.allowed) return { blocked: "uid", ...uidCheck };
        }
      }

      const ttl = expireAt(nowMs);
      tx.set(ipRef, { ...ipCheck.next, expireAt: ttl });
      tx.set(
        phoneRef,
        { ...(phoneCheck?.next ?? {}), activeChallengeId: challengeId, expireAt: ttl },
        { merge: true },
      );
      if (globalCheck) tx.set(globalRef, { ...globalCheck.next, expireAt: ttl });
      if (uidCheck) tx.set(uidRef, { ...uidCheck.next, expireAt: ttl });
      tx.set(challengeRef, {
        phone,
        purpose,
        uid,
        reserved,
        codeHmac: reserved
          ? null
          : challengeHmac(config.pepper, { code, challengeId, phone, purpose, uid }),
        status: "active",
        attempts: 0,
        createdAtMs: nowMs,
        expiresAtMs: nowMs + OTP_TTL_MS,
        expireAt: ttl,
      });
      return { blocked: null };
    });

    return { ...outcome, challengeId, challengeRef, phoneRef, ipRef, globalRef, uidRef };
  }

  /** Returns the quota of a send that definitely never left Taqnyat. */
  async function refundSend(reservation) {
    const { challengeId, challengeRef, phoneRef, ipRef, globalRef, uidRef } = reservation;
    await otpDb.runTransaction(async (tx) => {
      const [phoneSnap, ipSnap, globalSnap, uidSnap] = await Promise.all([
        tx.get(phoneRef),
        tx.get(ipRef),
        tx.get(globalRef),
        uidRef ? tx.get(uidRef) : Promise.resolve(null),
      ]);
      const decrement = (ref, snap) => {
        if (snap?.exists) {
          tx.update(ref, { count: Math.max(0, (snap.data().count || 0) - 1) });
        }
      };
      decrement(ipRef, ipSnap);
      decrement(globalRef, globalSnap);
      if (uidRef) decrement(uidRef, uidSnap);
      if (phoneSnap.exists && phoneSnap.data().activeChallengeId === challengeId) {
        tx.update(phoneRef, { ...refundPhoneSend(phoneSnap.data()), activeChallengeId: null });
      }
      tx.delete(challengeRef);
    });
  }

  async function deliver({ input, code, reservation, config }) {
    if (!config.taqToken || !config.taqSender) {
      await refundSend(reservation);
      logger.error("otp_sms_not_configured", { alert: "otp_sms_not_configured" });
      throw otpError("internal-error");
    }
    const result = await sendSms({
      token: config.taqToken,
      sender: config.taqSender,
      phone: input.phone,
      body: smsBody(code, input.locale, input.app),
    });
    if (result.status === "sent") return;
    if (result.status === "ambiguous") {
      // The message may still arrive, so the code stays valid.
      logger.warn("otp_sms_ambiguous", { phone: maskPhone(input.phone), reason: result.reason });
      return;
    }
    await refundSend(reservation);
    const log = result.alert ? logger.error : logger.warn;
    log("otp_sms_failed", {
      ...(result.alert ? { alert: "otp_sms_failed" } : {}),
      phone: maskPhone(input.phone),
      httpStatus: result.httpStatus,
      providerCode: result.providerCode,
      providerMessage: result.providerMessage,
    });
    throw otpError(result.appCode);
  }

  async function handleRequestOtp(request) {
    const config = getConfig();
    const input = parseRequestInput(request.data, request.app?.appId);
    logAppCheck("requestOtp", request);

    const reserved = isReserved(input.phone, config.reserved);
    let session = null;
    if (input.purpose === PURPOSE_CHANGE_PHONE) {
      session = await phoneChange.requireSession(request, input.expectedUid, config.reserved);
      if (reserved || session.phone === input.phone) throw otpError("phone-already-in-use");
      await phoneChange.assertAvailable(input.phone, session.uid);
    }

    const code = reserved ? null : generateCode();
    const reservation = await reserveSend({
      input,
      session,
      reserved,
      attested: Boolean(request.app),
      ip: clientIp(request.rawRequest?.headers, request.rawRequest?.ip),
      code,
      config,
    });
    if (reservation.blocked) {
      logger.warn("otp_rate_limited", {
        scope: reservation.blocked,
        phone: maskPhone(input.phone),
      });
      throw otpError("too-many-requests", { retryAfterSeconds: reservation.retryAfterSeconds });
    }

    if (!reserved) await deliver({ input, code, reservation, config });

    // Reserved and ordinary numbers get identical responses.
    return {
      verificationId: `${VERIFICATION_PREFIX}${reservation.challengeId}`,
      resendAfterSeconds: Math.ceil(PHONE_LIMITS.cooldownMs / 1000),
      expiresInSeconds: Math.ceil(OTP_TTL_MS / 1000),
    };
  }

  async function mintToken(phone, reservedEntry) {
    if (reservedEntry) {
      // The private code proves this login, so the account need not hold the
      // number, and is safer without it: Firebase phone auth can then never
      // text that SIM, which the project does not control, into this account.
      // A number that turns up on a different account still blocks the login.
      const [user, holder] = await Promise.all([
        auth.getUser(reservedEntry.uid).catch(() => null),
        auth.getUserByPhoneNumber(phone).catch((error) => {
          if (error?.code === "auth/user-not-found") return null;
          throw error;
        }),
      ]);
      if (!user || user.disabled || (holder && holder.uid !== user.uid)) {
        logger.error("otp_reserved_account_mismatch", {
          alert: "otp_reserved_login_blocked",
          phone: maskPhone(phone),
        });
        throw otpError("internal-error");
      }
      logger.warn("otp_reserved_login", { alert: "otp_reserved_login", phone: maskPhone(phone) });
      return auth.createCustomToken(user.uid);
    }

    let user;
    try {
      user = await auth.getUserByPhoneNumber(phone);
    } catch (error) {
      if (error?.code !== "auth/user-not-found") throw error;
      try {
        user = await auth.createUser({ phoneNumber: phone });
      } catch (createError) {
        // Two devices finishing at once: the other request created the user.
        if (createError?.code !== "auth/phone-number-already-exists") throw createError;
        user = await auth.getUserByPhoneNumber(phone);
      }
    }
    if (user.disabled) throw otpError("user-disabled");
    return auth.createCustomToken(user.uid);
  }

  async function handleVerifyOtp(request) {
    const config = getConfig();
    const input = parseVerifyInput(request.data);
    logAppCheck("verifyOtp", request);

    const challengeRef = collection("challenges").doc(input.challengeId);
    const initial = await challengeRef.get();
    if (!initial.exists) throw otpError("session-expired");
    const { phone, purpose, uid, reserved, codeHmac } = initial.data();

    let session = null;
    if (purpose === PURPOSE_CHANGE_PHONE) {
      session = await phoneChange.requireSession(request, input.expectedUid, config.reserved);
      if (session.uid !== uid) throw otpError("session-expired");
    }

    const reservedEntry = reserved ? config.reserved[phone] ?? null : null;
    const expectedHmac = reserved ? reservedEntry?.codeHmac ?? null : codeHmac;
    const suppliedHmac = reserved
      ? reservedCodeHmac(config.pepper, { phone, code: input.code })
      : challengeHmac(config.pepper, {
          code: input.code,
          challengeId: input.challengeId,
          phone,
          purpose,
          uid,
        });

    const phoneRef = collection("phones").doc(stateKey(config.pepper, "phone", phone));
    const guardRef = reserved
      ? collection("reservedGuards").doc(stateKey(config.pepper, "guard", phone))
      : null;
    const journalRef = purpose === PURPOSE_CHANGE_PHONE ? phoneChange.journalRef(uid) : null;
    let journal = null;

    const decision = await otpDb.runTransaction(async (tx) => {
      const nowMs = now();
      const [challengeSnap, phoneSnap, guardSnap, journalSnap] = await Promise.all([
        tx.get(challengeRef),
        tx.get(phoneRef),
        guardRef ? tx.get(guardRef) : Promise.resolve(null),
        journalRef ? tx.get(journalRef) : Promise.resolve(null),
      ]);
      const result = decideVerification({
        challenge: challengeSnap.exists
          ? { id: challengeSnap.id, ...challengeSnap.data() }
          : null,
        activeChallengeId: phoneSnap.data()?.activeChallengeId ?? null,
        expectedHmac,
        suppliedHmac,
        requestId: input.requestId,
        nowMs,
        lockedUntilMs: guardSnap?.data()?.lockedUntilMs ?? 0,
      });

      if (result.outcome === "invalid") {
        tx.update(challengeRef, { attempts: result.attempts });
        if (guardRef) {
          tx.set(guardRef, nextReservedGuard(guardSnap.data(), nowMs), { merge: true });
        }
      }
      if (result.outcome === "ok") {
        if (journalSnap?.data()?.open) return { outcome: "busy" };
        tx.update(challengeRef, {
          status: "consumed",
          consumedRequestId: input.requestId,
          remintUntilMs: nowMs + REMINT_WINDOW_MS,
        });
        tx.update(phoneRef, { activeChallengeId: null });
        if (guardRef) tx.set(guardRef, { failures: 0, lockedUntilMs: 0 });
        if (journalRef) {
          journal = phoneChange.buildJournal({
            uid,
            oldPhone: session.phone,
            newPhone: phone,
            challengeId: input.challengeId,
          });
          tx.set(journalRef, journal);
        }
      }
      return result;
    });

    switch (decision.outcome) {
      case "ok":
      case "remint":
        break;
      case "invalid":
        if (reserved) {
          logger.error("otp_reserved_failure", {
            alert: "otp_reserved_failure",
            phone: maskPhone(phone),
          });
        }
        throw otpError("invalid-verification-code");
      case "locked":
      case "busy":
        throw otpError("too-many-requests");
      default:
        throw otpError("session-expired");
    }

    if (purpose === PURPOSE_CHANGE_PHONE) {
      const newPhone =
        decision.outcome === "ok" ? await phoneChange.finish(journal) : await phoneChange.resultOf(uid);
      return { phone: newPhone };
    }
    return { token: await mintToken(phone, reservedEntry) };
  }

  return { handleRequestOtp, handleVerifyOtp };
}

module.exports = { createOtpService };
