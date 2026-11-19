"use strict";

// Changes a user's phone number while keeping their UID.
//
// Order matters. checkUser() in both apps hands a profile to whoever signs in
// with a number still stored on it, so profile docs must stop holding the old
// number before the Auth record moves. Every step is journaled in
// `phoneChanges/{uid}`, so the sweeper can finish or undo an interrupted change.

const { FieldValue, Timestamp } = require("firebase-admin/firestore");
const { otpError } = require("./errors");
const { STATE_TTL_MS, isReserved, maskPhone } = require("./otpCore");

const BATCH_SIZE = 400;
const SWEEP_AFTER_MS = 3 * 60 * 1000;
const DENORMALIZED_RETRIES = 3;

const STATUS = Object.freeze({
  PENDING: "pending",
  PROFILES_UPDATED: "profiles_updated",
  AUTH_UPDATED: "auth_updated",
  COMPLETE: "complete",
  FAILED: "failed",
});

// `admins` docs use `phoneNumber`; older migrations also wrote `phone` there.
const PROFILE_COLLECTIONS = Object.freeze([
  { collection: "customers", required: ["phone"], optional: [] },
  { collection: "users", required: ["phone"], optional: [] },
  { collection: "admins", required: ["phoneNumber"], optional: ["phone"] },
]);

const COLLISION_QUERIES = Object.freeze([
  ["customers", "phone"],
  ["users", "phone"],
  ["admins", "phoneNumber"],
  ["admins", "phone"],
  ["pending_admins", "phoneNumber"],
]);

function createPhoneChangeService({ db, otpDb, auth, logger, now = Date.now, sleep }) {
  const wait = sleep || ((ms) => new Promise((resolve) => setTimeout(resolve, ms)));
  const journalRef = (uid) => otpDb.collection("phoneChanges").doc(uid);

  async function requireSession(request, expectedUid, reservedAccounts) {
    const authContext = request.auth;
    if (!authContext?.uid || !authContext.rawToken) {
      throw otpError("requires-recent-login");
    }
    // The app may hold one account locally and another in Firebase after a
    // biometric login, so the caller must say which account it means to change.
    if (!expectedUid || expectedUid !== authContext.uid) {
      throw otpError("requires-recent-login");
    }
    if (authContext.token?.firebase?.sign_in_provider === "anonymous") {
      throw otpError("requires-recent-login");
    }
    try {
      await auth.verifyIdToken(authContext.rawToken, true);
    } catch (_) {
      throw otpError("requires-recent-login");
    }
    const user = await auth.getUser(authContext.uid);
    if (user.disabled) throw otpError("user-disabled");
    if (!user.phoneNumber) throw otpError("requires-recent-login");
    if (isReserved(user.phoneNumber, reservedAccounts)) {
      throw otpError("phone-already-in-use");
    }
    return { uid: user.uid, phone: user.phoneNumber };
  }

  async function findAuthHolder(phone) {
    try {
      return await auth.getUserByPhoneNumber(phone);
    } catch (error) {
      if (error?.code === "auth/user-not-found") return null;
      throw error;
    }
  }

  async function hasAccountData(uid) {
    const profiles = await Promise.all(
      PROFILE_COLLECTIONS.map(({ collection }) => db.collection(collection).doc(uid).get()),
    );
    if (profiles.some((doc) => doc.exists)) return true;
    const bookings = await Promise.all([
      db.collection("bookings").where("customer.uid", "==", uid).limit(1).get(),
      db.collection("bookings").where("agent.uid", "==", uid).limit(1).get(),
    ]);
    return bookings.some((snapshot) => !snapshot.empty);
  }

  async function assertAvailable(phone, uid) {
    const snapshots = await Promise.all(
      COLLISION_QUERIES.map(([collection, field]) =>
        db.collection(collection).where(field, "==", phone).limit(5).get(),
      ),
    );
    const collides = snapshots.some((snapshot, index) =>
      snapshot.docs.some(
        (doc) => COLLISION_QUERIES[index][0] === "pending_admins" || doc.id !== uid,
      ),
    );
    if (collides) throw otpError("phone-already-in-use");

    const holder = await findAuthHolder(phone);
    if (holder && holder.uid !== uid && (await hasAccountData(holder.uid))) {
      throw otpError("phone-already-in-use");
    }
    return holder && holder.uid !== uid ? holder : null;
  }

  function buildJournal({ uid, oldPhone, newPhone, challengeId }) {
    const nowMs = now();
    return {
      uid,
      oldPhone,
      newPhone,
      challengeId,
      status: STATUS.PENDING,
      open: true,
      startedAtMs: nowMs,
      updatedAtMs: nowMs,
    };
  }

  async function captureProfiles(uid) {
    const previous = {};
    await Promise.all(
      PROFILE_COLLECTIONS.map(async ({ collection, required, optional }) => {
        const doc = await db.collection(collection).doc(uid).get();
        if (!doc.exists) return;
        const data = doc.data();
        const fields = {};
        for (const field of required) fields[field] = data[field] ?? null;
        for (const field of optional) {
          if (data[field] !== undefined) fields[field] = data[field];
        }
        previous[collection] = fields;
      }),
    );
    return previous;
  }

  async function writeProfiles(uid, previous, newPhone) {
    const batch = db.batch();
    for (const [collection, fields] of Object.entries(previous)) {
      const update = { updatedAt: FieldValue.serverTimestamp() };
      for (const field of Object.keys(fields)) update[field] = newPhone;
      batch.update(db.collection(collection).doc(uid), update);
    }
    await batch.commit();
  }

  /** Restores only the fields that still hold the number this change wrote. */
  async function revertProfiles(uid, previous, newPhone) {
    if (!previous) return;
    await Promise.all(
      Object.entries(previous).map(async ([collection, fields]) => {
        const ref = db.collection(collection).doc(uid);
        const doc = await ref.get();
        if (!doc.exists) return;
        const data = doc.data();
        const update = {};
        for (const [field, value] of Object.entries(fields)) {
          if (data[field] === newPhone) update[field] = value;
        }
        if (Object.keys(update).length > 0) await ref.update(update);
      }),
    );
  }

  async function commitInChunks(updates) {
    for (let index = 0; index < updates.length; index += BATCH_SIZE) {
      const batch = db.batch();
      for (const { ref, data } of updates.slice(index, index + BATCH_SIZE)) {
        batch.update(ref, data);
      }
      await batch.commit();
    }
  }

  async function updateDenormalizedCopies({ uid, oldPhone, newPhone }) {
    const customerUpdate = (doc) => ({
      ref: doc.ref,
      data: {
        "customer.phone": newPhone,
        ...(doc.data().phone === oldPhone ? { phone: newPhone } : {}),
      },
    });
    const [customerBookings, agentBookings, assignmentRequests, tipping] = await Promise.all([
      db.collection("bookings").where("customer.uid", "==", uid).get(),
      db.collection("bookings").where("agent.uid", "==", uid).get(),
      db.collection("auto-assignment_requests").where("customer.uid", "==", uid).get(),
      db.collection("tipping").doc(uid).get(),
    ]);

    const updates = [
      ...customerBookings.docs.map(customerUpdate),
      ...assignmentRequests.docs.map(customerUpdate),
      ...agentBookings.docs.map((doc) => ({
        ref: doc.ref,
        data: { "agent.phone": newPhone },
      })),
    ];
    if (tipping.exists) {
      updates.push({ ref: tipping.ref, data: { agentPhone: newPhone } });
    }
    await commitInChunks(updates);
  }

  async function closeJournal(uid, status, extra = {}) {
    const nowMs = now();
    await journalRef(uid).update({
      status,
      open: false,
      updatedAtMs: nowMs,
      expireAt: Timestamp.fromMillis(nowMs + STATE_TTL_MS),
      ...extra,
    });
  }

  /**
   * Bookings and tips only display the number, so a failure here does not undo
   * the change. The journal stays open and the sweeper retries it.
   */
  async function completeCopies(entry) {
    for (let attempt = 1; attempt <= DENORMALIZED_RETRIES; attempt += 1) {
      try {
        await updateDenormalizedCopies(entry);
        await closeJournal(entry.uid, STATUS.COMPLETE);
        return true;
      } catch (error) {
        logger.warn("phone_change_copies_retry", {
          uid: entry.uid,
          attempt,
          error: error?.message,
        });
        if (attempt < DENORMALIZED_RETRIES) await wait(attempt * 500);
      }
    }
    return false;
  }

  /** Safe to re-run: the sweeper resumes interrupted entries through here. */
  async function finish(entry) {
    const { uid, newPhone } = entry;
    let previous = entry.previous || null;
    try {
      const orphan = await assertAvailable(newPhone, uid);
      if (!previous) {
        previous = await captureProfiles(uid);
        await journalRef(uid).update({ previous, updatedAtMs: now() });
      }
      await writeProfiles(uid, previous, newPhone);
      await journalRef(uid).update({
        status: STATUS.PROFILES_UPDATED,
        updatedAtMs: now(),
      });
      if (orphan) {
        await auth.updateUser(orphan.uid, { phoneNumber: null, disabled: true });
      }
      await auth.updateUser(uid, { phoneNumber: newPhone });
      await journalRef(uid).update({
        status: STATUS.AUTH_UPDATED,
        updatedAtMs: now(),
      });
    } catch (error) {
      await revertProfiles(uid, previous, newPhone);
      await closeJournal(uid, STATUS.FAILED, {
        error: error?.details?.code || error?.code || "unknown",
      });
      logger.error("phone_change_failed", {
        alert: "phone_change_failed",
        uid,
        phone: maskPhone(newPhone),
        error: error?.message,
      });
      if (
        error?.code === "auth/phone-number-already-exists" ||
        error?.details?.code === "phone-already-in-use"
      ) {
        throw otpError("phone-already-in-use");
      }
      throw otpError("internal-error");
    }
    await completeCopies({ ...entry, previous });
    return newPhone;
  }

  /** Answers a retry whose first response was lost. */
  async function resultOf(uid) {
    const snapshot = await journalRef(uid).get();
    const entry = snapshot.exists ? snapshot.data() : null;
    if (entry?.status === STATUS.COMPLETE || entry?.status === STATUS.AUTH_UPDATED) {
      return entry.newPhone;
    }
    if (entry?.status === STATUS.FAILED) {
      throw otpError(entry.error === "phone-already-in-use" ? entry.error : "internal-error");
    }
    throw otpError("too-many-requests");
  }

  async function sweep() {
    const snapshot = await otpDb
      .collection("phoneChanges")
      .where("open", "==", true)
      .limit(50)
      .get();
    const cutoff = now() - SWEEP_AFTER_MS;
    for (const doc of snapshot.docs) {
      const entry = doc.data();
      if (entry.updatedAtMs > cutoff) continue;
      try {
        const user = await auth.getUser(entry.uid);
        if (entry.status === STATUS.AUTH_UPDATED || user.phoneNumber === entry.newPhone) {
          await completeCopies(entry);
        } else {
          await finish(entry);
        }
      } catch (error) {
        logger.error("phone_change_sweep_failed", {
          alert: "phone_change_failed",
          uid: entry.uid,
          error: error?.message,
        });
      }
    }
  }

  return {
    assertAvailable,
    buildJournal,
    finish,
    journalRef,
    requireSession,
    resultOf,
    sweep,
  };
}

module.exports = { STATUS, createPhoneChangeService };
