"use strict";

// Pure OTP rules: no Firebase and no network, so every security decision here
// can be unit tested directly.

const crypto = require("crypto");

const VERIFICATION_PREFIX = "otp1:";
const PURPOSE_LOGIN = "login";
const PURPOSE_CHANGE_PHONE = "change_phone";

const MINUTE_MS = 60 * 1000;
const HOUR_MS = 60 * MINUTE_MS;
const DAY_MS = 24 * HOUR_MS;

const OTP_TTL_MS = 5 * MINUTE_MS;
const MAX_ATTEMPTS = 5;
// A verified code can be re-exchanged briefly, so a response lost on a bad
// network does not strand the user with a consumed code.
const REMINT_WINDOW_MS = 2 * MINUTE_MS;
const STATE_TTL_MS = 2 * DAY_MS;

const RESERVED_MAX_FAILURES = 5;
const RESERVED_LOCK_MS = HOUR_MS;

const PHONE_LIMITS = Object.freeze({
  cooldownMs: MINUTE_MS,
  perHour: 5,
  perDay: 10,
});
const PHONE_CHANGES_PER_DAY = 5;
const GLOBAL_COUNTER_SHARDS = 10;

// These numbers must never receive an SMS from us, whatever the secret says: we
// do not hold the SIM for them, and a code delivered to the real subscriber
// would open a core admin account.
const NEVER_SMS_NUMBERS = Object.freeze(new Set(["+966501234567"]));

const SAUDI_MOBILE = /^\+9665\d{8}$/;
const HEX_64 = /^[0-9a-f]{64}$/;
const PRIVATE_IP =
  /^(10\.|127\.|169\.254\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.|::1$|f[cd][0-9a-f]{2}:|fe80:)/i;

function isSaudiMobile(phone) {
  return typeof phone === "string" && SAUDI_MOBILE.test(phone);
}

/** For logs only: enough to correlate reports without storing the number. */
function maskPhone(phone) {
  if (typeof phone !== "string" || phone.length < 6) return "***";
  return `${phone.slice(0, 5)}*****${phone.slice(-2)}`;
}

function generateCode(randomInt = crypto.randomInt) {
  return String(randomInt(0, 1000000)).padStart(6, "0");
}

function newChallengeId() {
  return crypto.randomBytes(16).toString("hex");
}

function hmacHex(pepper, ...parts) {
  return crypto
    .createHmac("sha256", pepper)
    .update(parts.map((part) => String(part ?? "")).join("\u001f"))
    .digest("hex");
}

/**
 * Binds a code to one challenge, number, purpose and account, so a code issued
 * for one of those can never be replayed against another.
 */
function challengeHmac(pepper, { code, challengeId, phone, purpose, uid }) {
  return hmacHex(pepper, "challenge", code, challengeId, phone, purpose, uid);
}

function reservedCodeHmac(pepper, { phone, code }) {
  return hmacHex(pepper, "reserved", phone, code);
}

/** Document id for per-number and per-IP state, so ids do not expose either. */
function stateKey(pepper, kind, value) {
  return hmacHex(pepper, "state", kind, value);
}

function hmacEquals(expected, supplied) {
  if (typeof expected !== "string" || typeof supplied !== "string") return false;
  if (!HEX_64.test(expected) || !HEX_64.test(supplied)) return false;
  return crypto.timingSafeEqual(
    Buffer.from(expected, "hex"),
    Buffer.from(supplied, "hex"),
  );
}

/**
 * Throws on anything malformed. Callers must fail closed: treating a bad secret
 * as "no reserved numbers" would turn reserved numbers into ordinary ones.
 */
function parseReservedAccounts(raw) {
  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch (_) {
    throw new Error("OTP_RESERVED_ACCOUNTS is not valid JSON");
  }
  if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
    throw new Error("OTP_RESERVED_ACCOUNTS must be a JSON object");
  }
  for (const [phone, entry] of Object.entries(parsed)) {
    if (!isSaudiMobile(phone)) {
      throw new Error("OTP_RESERVED_ACCOUNTS has an invalid phone key");
    }
    if (
      !entry ||
      typeof entry.uid !== "string" ||
      entry.uid.length === 0 ||
      typeof entry.codeHmac !== "string" ||
      !HEX_64.test(entry.codeHmac)
    ) {
      throw new Error("OTP_RESERVED_ACCOUNTS has an invalid entry");
    }
  }
  return Object.freeze(parsed);
}

function isReserved(phone, accounts) {
  return (
    NEVER_SMS_NUMBERS.has(phone) ||
    Object.prototype.hasOwnProperty.call(accounts || {}, phone)
  );
}

/**
 * The caller's address. The rightmost public hop is the one Google's front end
 * appended; anything to its left was supplied by the client and can be forged.
 */
function clientIp(headers = {}, fallback = "unknown") {
  const raw = headers["x-forwarded-for"];
  const value = Array.isArray(raw) ? raw.join(",") : raw || "";
  const hops = value
    .split(",")
    .map((hop) => hop.trim())
    .filter(Boolean);
  for (let i = hops.length - 1; i >= 0; i -= 1) {
    if (!PRIVATE_IP.test(hops[i])) return hops[i];
  }
  return fallback || "unknown";
}

function rollWindow(startMs, count, nowMs, windowMs) {
  if (!startMs || nowMs - startMs >= windowMs) {
    return { startMs: nowMs, count: 0 };
  }
  return { startMs, count: count || 0 };
}

function retryAfter(startMs, windowMs, nowMs) {
  return Math.max(1, Math.ceil((startMs + windowMs - nowMs) / 1000));
}

/** Fixed-window counter shared by the per-IP, per-UID and global limits. */
function checkWindow(state, nowMs, windowMs, max) {
  const window = rollWindow(state?.startMs, state?.count, nowMs, windowMs);
  if (window.count >= max) {
    return {
      allowed: false,
      retryAfterSeconds: retryAfter(window.startMs, windowMs, nowMs),
    };
  }
  return {
    allowed: true,
    next: { startMs: window.startMs, count: window.count + 1 },
  };
}

function checkPhoneSend(state, nowMs, limits = PHONE_LIMITS) {
  const lastSentAtMs = state?.lastSentAtMs || 0;
  if (lastSentAtMs && nowMs - lastSentAtMs < limits.cooldownMs) {
    return {
      allowed: false,
      retryAfterSeconds: retryAfter(lastSentAtMs, limits.cooldownMs, nowMs),
    };
  }
  const hour = rollWindow(state?.hourStartMs, state?.hourCount, nowMs, HOUR_MS);
  if (hour.count >= limits.perHour) {
    return {
      allowed: false,
      retryAfterSeconds: retryAfter(hour.startMs, HOUR_MS, nowMs),
    };
  }
  const day = rollWindow(state?.dayStartMs, state?.dayCount, nowMs, DAY_MS);
  if (day.count >= limits.perDay) {
    return {
      allowed: false,
      retryAfterSeconds: retryAfter(day.startMs, DAY_MS, nowMs),
    };
  }
  return {
    allowed: true,
    next: {
      lastSentAtMs: nowMs,
      previousSentAtMs: lastSentAtMs,
      hourStartMs: hour.startMs,
      hourCount: hour.count + 1,
      dayStartMs: day.startMs,
      dayCount: day.count + 1,
    },
  };
}

/** Gives back one send after a definite delivery failure. */
function refundPhoneSend(state) {
  return {
    lastSentAtMs: state?.previousSentAtMs || 0,
    hourCount: Math.max(0, (state?.hourCount || 0) - 1),
    dayCount: Math.max(0, (state?.dayCount || 0) - 1),
  };
}

/**
 * Decides one verification attempt. It returns an outcome and never throws,
 * because an exception inside a Firestore transaction would roll back the
 * attempt counter and allow unlimited guesses.
 */
function decideVerification({
  challenge,
  activeChallengeId,
  expectedHmac,
  suppliedHmac,
  requestId,
  nowMs,
  lockedUntilMs = 0,
}) {
  if (!challenge) return { outcome: "expired" };

  if (challenge.status === "consumed") {
    const canRemint =
      typeof requestId === "string" &&
      requestId.length > 0 &&
      challenge.consumedRequestId === requestId &&
      nowMs < (challenge.remintUntilMs || 0) &&
      hmacEquals(expectedHmac, suppliedHmac);
    return { outcome: canRemint ? "remint" : "expired" };
  }

  if (challenge.status !== "active" || nowMs >= challenge.expiresAtMs) {
    return { outcome: "expired" };
  }
  if (activeChallengeId !== challenge.id) return { outcome: "expired" };
  if (lockedUntilMs > nowMs) return { outcome: "locked" };

  const attempts = challenge.attempts || 0;
  if (attempts >= MAX_ATTEMPTS) return { outcome: "locked" };
  if (!hmacEquals(expectedHmac, suppliedHmac)) {
    return { outcome: "invalid", attempts: attempts + 1 };
  }
  return { outcome: "ok" };
}

/** Failure streak for a reserved number. New challenges do not reset it. */
function nextReservedGuard(guard, nowMs) {
  const failures = (guard?.failures || 0) + 1;
  return {
    failures,
    lockedUntilMs:
      failures >= RESERVED_MAX_FAILURES
        ? nowMs + RESERVED_LOCK_MS
        : guard?.lockedUntilMs || 0,
  };
}

function normalizeLocale(locale) {
  const language = String(locale || "")
    .toLowerCase()
    .split(/[-_]/)[0];
  return language === "en" || language === "ur" ? language : "ar";
}

const APP_CUSTOMER = "customer";
const APP_TECHNICIAN = "technician";

// Both apps live in this Firebase project. A verified App Check token names
// the calling app by these IDs, which a client cannot fake.
const APP_BY_FIREBASE_APP_ID = Object.freeze({
  "1:629201660527:android:830540db26fc90fb2dfb9a": APP_CUSTOMER,
  "1:629201660527:ios:975df7f9cab623bc2dfb9a": APP_CUSTOMER,
  "1:629201660527:android:2e4177f0e86629d12dfb9a": APP_TECHNICIAN,
  "1:629201660527:ios:bb1f3d34b1a5dd122dfb9a": APP_TECHNICIAN,
});

const APP_NAMES = Object.freeze({
  [APP_CUSTOMER]: "Aboglumbo Tools",
  [APP_TECHNICIAN]: "Aboglumbo Technician",
});

// Builds from before the `app` field was sent.
const DEFAULT_APP_NAME = "Aboglumbo";

/**
 * Which app asked for the code: the App Check identity when present,
 * otherwise the app the client says it is. Only the SMS wording depends on
 * it, so an unverified claim is acceptable.
 */
function resolveApp(attestedAppId, claimedApp) {
  const attested = APP_BY_FIREBASE_APP_ID[attestedAppId];
  if (attested) return attested;
  return claimedApp === APP_CUSTOMER || claimedApp === APP_TECHNICIAN ? claimedApp : null;
}

/**
 * Exactly one 6-digit number per message: both apps' SMS autofill matches
 * \b\d{6}\b. Arabic and Urdu stay within one 70-character SMS segment, and
 * open with their own script so phones lay them out right to left.
 */
function smsBody(code, locale, app = null) {
  const name = APP_NAMES[app] || DEFAULT_APP_NAME;
  switch (normalizeLocale(locale)) {
    case "en":
      return `Your ${name} verification code is ${code}. It expires in 5 minutes.`;
    case "ur":
      return `آپ کا ${name} تصدیقی کوڈ ${code} ہے۔ 5 منٹ تک درست ہے۔`;
    default:
      return `رمز التحقق في ${name} هو ${code}. صالح لمدة 5 دقائق.`;
  }
}

module.exports = {
  APP_CUSTOMER,
  APP_NAMES,
  APP_TECHNICIAN,
  DAY_MS,
  GLOBAL_COUNTER_SHARDS,
  HOUR_MS,
  MAX_ATTEMPTS,
  NEVER_SMS_NUMBERS,
  OTP_TTL_MS,
  PHONE_CHANGES_PER_DAY,
  PHONE_LIMITS,
  PURPOSE_CHANGE_PHONE,
  PURPOSE_LOGIN,
  REMINT_WINDOW_MS,
  RESERVED_LOCK_MS,
  RESERVED_MAX_FAILURES,
  STATE_TTL_MS,
  VERIFICATION_PREFIX,
  challengeHmac,
  checkPhoneSend,
  checkWindow,
  clientIp,
  decideVerification,
  generateCode,
  hmacEquals,
  isReserved,
  isSaudiMobile,
  maskPhone,
  newChallengeId,
  nextReservedGuard,
  normalizeLocale,
  parseReservedAccounts,
  refundPhoneSend,
  reservedCodeHmac,
  resolveApp,
  smsBody,
  stateKey,
};
