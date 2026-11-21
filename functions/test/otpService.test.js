"use strict";

const assert = require("node:assert/strict");
const { beforeEach, describe, it } = require("node:test");

const core = require("../src/auth/otpCore");
const { createOtpService } = require("../src/auth/otpService");
const { STATUS, createPhoneChangeService } = require("../src/auth/phoneChange");
const { FakeFirestore } = require("./helpers/fakeFirestore");

const PEPPER = "test-pepper";
const PHONE = "+966555724363";
const NEW_PHONE = "+966511111111";
const CORE_ADMIN = "+966501234567";
const CORE_ADMIN_UID = "core-admin-uid";
const CORE_ADMIN_CODE = "482913";
const REQUEST_ID = "request-0001";

const silentLogger = { info() {}, warn() {}, error() {} };

function fakeAuth() {
  const users = new Map();
  let nextId = 1;
  const notFound = () => Object.assign(new Error("not found"), { code: "auth/user-not-found" });
  const auth = {
    users,
    failUpdate: null,
    add(user) {
      users.set(user.uid, { disabled: false, ...user });
    },
    async getUser(uid) {
      if (!users.has(uid)) throw notFound();
      return users.get(uid);
    },
    async getUserByPhoneNumber(phone) {
      for (const user of users.values()) {
        if (user.phoneNumber === phone) return user;
      }
      throw notFound();
    },
    async createUser({ phoneNumber }) {
      const user = { uid: `new-${nextId}`, phoneNumber, disabled: false };
      nextId += 1;
      users.set(user.uid, user);
      return user;
    },
    async updateUser(uid, update) {
      if (auth.failUpdate) throw auth.failUpdate;
      Object.assign(users.get(uid), update);
    },
    async createCustomToken(uid) {
      return `token:${uid}`;
    },
    async verifyIdToken() {
      return {};
    },
  };
  return auth;
}

function harness({ reservedRaw } = {}) {
  const otpDb = new FakeFirestore();
  const db = new FakeFirestore();
  const auth = fakeAuth();
  const sms = { sent: [], result: { status: "sent" } };
  let nowMs = 1_000_000_000;

  const reserved = core.parseReservedAccounts(
    reservedRaw ??
      JSON.stringify({
        [CORE_ADMIN]: {
          uid: CORE_ADMIN_UID,
          codeHmac: core.reservedCodeHmac(PEPPER, { phone: CORE_ADMIN, code: CORE_ADMIN_CODE }),
        },
      }),
  );
  const config = {
    pepper: PEPPER,
    reserved,
    taqToken: "token",
    taqSender: "Sender",
    limits: { globalHourly: 600, unattestedHourly: 120, ipHourly: 30 },
  };
  const phoneChange = createPhoneChangeService({
    db,
    otpDb,
    auth,
    logger: silentLogger,
    now: () => nowMs,
    sleep: async () => {},
  });
  const service = createOtpService({
    otpDb,
    auth,
    phoneChange,
    sendSms: async (message) => {
      sms.sent.push(message);
      return sms.result;
    },
    getConfig: () => config,
    logger: silentLogger,
    now: () => nowMs,
  });
  return {
    auth,
    config,
    db,
    otpDb,
    phoneChange,
    service,
    sms,
    advance: (ms) => {
      nowMs += ms;
    },
  };
}

function loginRequest(phone = PHONE, ip = "203.0.113.5") {
  return {
    data: { phone, purpose: "login", locale: "ar" },
    rawRequest: { headers: { "x-forwarded-for": ip } },
  };
}

function sessionFor(uid) {
  return {
    uid,
    rawToken: "id-token",
    token: { firebase: { sign_in_provider: "custom" } },
  };
}

function sentCode(sms) {
  return sms.sent[sms.sent.length - 1].body.match(/\b\d{6}\b/)[0];
}

async function rejectsWith(promise, appCode) {
  await assert.rejects(promise, (error) => {
    assert.equal(error.details?.code, appCode);
    return true;
  });
}

const verifyRequest = (verificationId, code, requestId = REQUEST_ID) => ({
  data: { verificationId, code, requestId },
});

describe("login", () => {
  let t;
  beforeEach(() => {
    t = harness();
  });

  it("sends a code and signs in a new user", async () => {
    const { verificationId } = await t.service.handleRequestOtp(loginRequest());
    assert.match(verificationId, /^otp1:[0-9a-f]{32}$/);
    assert.equal(t.sms.sent[0].phone, PHONE);

    const result = await t.service.handleVerifyOtp(verifyRequest(verificationId, sentCode(t.sms)));
    assert.equal(result.token, "token:new-1");
    assert.equal(t.auth.users.get("new-1").phoneNumber, PHONE);
  });

  it("keeps the UID of an existing phone user", async () => {
    t.auth.add({ uid: "existing", phoneNumber: PHONE });
    const { verificationId } = await t.service.handleRequestOtp(loginRequest());
    const result = await t.service.handleVerifyOtp(verifyRequest(verificationId, sentCode(t.sms)));
    assert.equal(result.token, "token:existing");
    assert.equal(t.auth.users.size, 1);
  });

  it("handles two devices creating the same user at once", async () => {
    const { verificationId } = await t.service.handleRequestOtp(loginRequest());
    const originalCreate = t.auth.createUser;
    t.auth.createUser = async ({ phoneNumber }) => {
      t.auth.add({ uid: "winner", phoneNumber });
      t.auth.createUser = originalCreate;
      throw Object.assign(new Error("exists"), { code: "auth/phone-number-already-exists" });
    };
    const result = await t.service.handleVerifyOtp(verifyRequest(verificationId, sentCode(t.sms)));
    assert.equal(result.token, "token:winner");
  });

  it("rejects disabled users", async () => {
    t.auth.add({ uid: "blocked", phoneNumber: PHONE, disabled: true });
    const { verificationId } = await t.service.handleRequestOtp(loginRequest());
    await rejectsWith(
      t.service.handleVerifyOtp(verifyRequest(verificationId, sentCode(t.sms))),
      "user-disabled",
    );
  });

  it("stores only a hash of the code", async () => {
    const { verificationId } = await t.service.handleRequestOtp(loginRequest());
    const stored = t.otpDb.read("challenges", verificationId.slice(5));
    assert.equal(JSON.stringify(stored).includes(sentCode(t.sms)), false);
  });

  it("persists wrong attempts and blocks the sixth, even with the right code", async () => {
    const { verificationId } = await t.service.handleRequestOtp(loginRequest());
    const code = sentCode(t.sms);
    const wrong = code === "000000" ? "000001" : "000000";
    for (let attempt = 1; attempt <= core.MAX_ATTEMPTS; attempt += 1) {
      await rejectsWith(
        t.service.handleVerifyOtp(verifyRequest(verificationId, wrong)),
        "invalid-verification-code",
      );
      assert.equal(t.otpDb.read("challenges", verificationId.slice(5)).attempts, attempt);
    }
    await rejectsWith(
      t.service.handleVerifyOtp(verifyRequest(verificationId, code)),
      "too-many-requests",
    );
  });

  it("rejects a replayed code from a different request", async () => {
    const { verificationId } = await t.service.handleRequestOtp(loginRequest());
    const code = sentCode(t.sms);
    await t.service.handleVerifyOtp(verifyRequest(verificationId, code));
    await rejectsWith(
      t.service.handleVerifyOtp(verifyRequest(verificationId, code, "request-0002")),
      "session-expired",
    );
  });

  it("re-mints for a retry of the same request, then stops", async () => {
    const { verificationId } = await t.service.handleRequestOtp(loginRequest());
    const code = sentCode(t.sms);
    await t.service.handleVerifyOtp(verifyRequest(verificationId, code));
    const retry = await t.service.handleVerifyOtp(verifyRequest(verificationId, code));
    assert.equal(retry.token, "token:new-1");

    t.advance(core.REMINT_WINDOW_MS);
    await rejectsWith(
      t.service.handleVerifyOtp(verifyRequest(verificationId, code)),
      "session-expired",
    );
  });

  it("expires codes", async () => {
    const { verificationId } = await t.service.handleRequestOtp(loginRequest());
    t.advance(core.OTP_TTL_MS);
    await rejectsWith(
      t.service.handleVerifyOtp(verifyRequest(verificationId, sentCode(t.sms))),
      "session-expired",
    );
  });

  it("invalidates the previous code on resend", async () => {
    const first = await t.service.handleRequestOtp(loginRequest());
    const firstCode = sentCode(t.sms);
    t.advance(core.PHONE_LIMITS.cooldownMs);
    await t.service.handleRequestOtp(loginRequest());
    await rejectsWith(
      t.service.handleVerifyOtp(verifyRequest(first.verificationId, firstCode)),
      "session-expired",
    );
  });

  it("enforces the resend cooldown", async () => {
    await t.service.handleRequestOtp(loginRequest());
    await rejectsWith(t.service.handleRequestOtp(loginRequest()), "too-many-requests");
    assert.equal(t.sms.sent.length, 1);
  });

  it("cannot be bypassed by forging X-Forwarded-For", async () => {
    t.config.limits.ipHourly = 1;
    await t.service.handleRequestOtp(loginRequest("+966500000001", "1.1.1.1, 203.0.113.5"));
    await rejectsWith(
      t.service.handleRequestOtp(loginRequest("+966500000002", "2.2.2.2, 203.0.113.5")),
      "too-many-requests",
    );
    assert.equal(t.sms.sent.length, 1);
  });

  it("rejects non-mobile numbers before spending an SMS", async () => {
    await rejectsWith(t.service.handleRequestOtp(loginRequest("+966112345678")), "invalid-phone-number");
    assert.equal(t.sms.sent.length, 0);
  });

  it("refunds quota when Taqnyat definitely failed", async () => {
    t.sms.result = { status: "failed", appCode: "quota-exceeded", alert: true };
    await rejectsWith(t.service.handleRequestOtp(loginRequest()), "quota-exceeded");
    t.sms.result = { status: "sent" };
    await t.service.handleRequestOtp(loginRequest());
    assert.equal(t.sms.sent.length, 2);
  });

  it("keeps the code valid when delivery is ambiguous", async () => {
    t.sms.result = { status: "ambiguous", reason: "TimeoutError" };
    const { verificationId } = await t.service.handleRequestOtp(loginRequest());
    const result = await t.service.handleVerifyOtp(verifyRequest(verificationId, sentCode(t.sms)));
    assert.equal(result.token, "token:new-1");
  });

  it("fails without storing a usable challenge when SMS is not configured", async () => {
    t.config.taqToken = null;
    await rejectsWith(t.service.handleRequestOtp(loginRequest()), "internal-error");
    assert.equal(t.sms.sent.length, 0);
  });
});

describe("reserved core admin number", () => {
  let t;
  beforeEach(() => {
    t = harness();
    t.auth.add({ uid: CORE_ADMIN_UID, phoneNumber: CORE_ADMIN });
  });

  it("never sends an SMS and logs in with the private code", async () => {
    const { verificationId } = await t.service.handleRequestOtp(loginRequest(CORE_ADMIN));
    assert.equal(t.sms.sent.length, 0);
    const result = await t.service.handleVerifyOtp(verifyRequest(verificationId, CORE_ADMIN_CODE));
    assert.equal(result.token, `token:${CORE_ADMIN_UID}`);
  });

  it("never sends an SMS even when missing from the secret", async () => {
    const empty = harness({ reservedRaw: "{}" });
    empty.auth.add({ uid: CORE_ADMIN_UID, phoneNumber: CORE_ADMIN });
    const { verificationId } = await empty.service.handleRequestOtp(loginRequest(CORE_ADMIN));
    assert.equal(empty.sms.sent.length, 0);
    await rejectsWith(
      empty.service.handleVerifyOtp(verifyRequest(verificationId, CORE_ADMIN_CODE)),
      "invalid-verification-code",
    );
  });

  it("refuses to log in if the number moved to another account", async () => {
    t.auth.users.clear();
    t.auth.add({ uid: CORE_ADMIN_UID });
    t.auth.add({ uid: "someone-else", phoneNumber: CORE_ADMIN });
    const { verificationId } = await t.service.handleRequestOtp(loginRequest(CORE_ADMIN));
    await rejectsWith(
      t.service.handleVerifyOtp(verifyRequest(verificationId, CORE_ADMIN_CODE)),
      "internal-error",
    );
  });

  it("logs in when no account holds the number", async () => {
    t.auth.users.clear();
    t.auth.add({ uid: CORE_ADMIN_UID });
    const { verificationId } = await t.service.handleRequestOtp(loginRequest(CORE_ADMIN));
    const result = await t.service.handleVerifyOtp(verifyRequest(verificationId, CORE_ADMIN_CODE));
    assert.equal(result.token, `token:${CORE_ADMIN_UID}`);
  });

  it("refuses a disabled core admin account", async () => {
    t.auth.users.clear();
    t.auth.add({ uid: CORE_ADMIN_UID, disabled: true });
    const { verificationId } = await t.service.handleRequestOtp(loginRequest(CORE_ADMIN));
    await rejectsWith(
      t.service.handleVerifyOtp(verifyRequest(verificationId, CORE_ADMIN_CODE)),
      "internal-error",
    );
  });

  it("never creates an Auth user for the number", async () => {
    t.auth.users.clear();
    const { verificationId } = await t.service.handleRequestOtp(loginRequest(CORE_ADMIN));
    await rejectsWith(
      t.service.handleVerifyOtp(verifyRequest(verificationId, CORE_ADMIN_CODE)),
      "internal-error",
    );
    assert.equal(t.auth.users.size, 0);
  });

  it("keeps counting failures across new challenges, then locks", async () => {
    for (let failure = 0; failure < core.RESERVED_MAX_FAILURES; failure += 1) {
      const { verificationId } = await t.service.handleRequestOtp(loginRequest(CORE_ADMIN));
      await rejectsWith(
        t.service.handleVerifyOtp(verifyRequest(verificationId, "000000")),
        "invalid-verification-code",
      );
    }
    const { verificationId } = await t.service.handleRequestOtp(loginRequest(CORE_ADMIN));
    await rejectsWith(
      t.service.handleVerifyOtp(verifyRequest(verificationId, CORE_ADMIN_CODE)),
      "too-many-requests",
    );

    t.advance(core.RESERVED_LOCK_MS);
    const next = await t.service.handleRequestOtp(loginRequest(CORE_ADMIN));
    const result = await t.service.handleVerifyOtp(verifyRequest(next.verificationId, CORE_ADMIN_CODE));
    assert.equal(result.token, `token:${CORE_ADMIN_UID}`);
  });

  it("is not throttled by repeated code requests", async () => {
    for (let request = 0; request < core.PHONE_LIMITS.perHour + 2; request += 1) {
      await t.service.handleRequestOtp(loginRequest(CORE_ADMIN));
    }
    assert.equal(t.sms.sent.length, 0);
  });

  it("cannot be the target of a phone change", async () => {
    t.auth.add({ uid: "u1", phoneNumber: PHONE });
    await rejectsWith(
      t.service.handleRequestOtp({
        auth: sessionFor("u1"),
        data: { phone: CORE_ADMIN, purpose: "change_phone", expectedUid: "u1" },
        rawRequest: { headers: {} },
      }),
      "phone-already-in-use",
    );
  });

  it("cannot be the source of a phone change", async () => {
    await rejectsWith(
      t.service.handleRequestOtp({
        auth: sessionFor(CORE_ADMIN_UID),
        data: { phone: NEW_PHONE, purpose: "change_phone", expectedUid: CORE_ADMIN_UID },
        rawRequest: { headers: {} },
      }),
      "phone-already-in-use",
    );
  });
});

describe("phone change", () => {
  const UID = "u1";
  let t;

  const changeRequest = (overrides = {}) => ({
    auth: sessionFor(UID),
    data: { phone: NEW_PHONE, purpose: "change_phone", expectedUid: UID, locale: "en" },
    rawRequest: { headers: { "x-forwarded-for": "203.0.113.5" } },
    ...overrides,
  });
  const confirm = (verificationId, code) => ({
    auth: sessionFor(UID),
    data: { verificationId, code, requestId: REQUEST_ID, expectedUid: UID },
  });

  beforeEach(() => {
    t = harness();
    t.auth.add({ uid: UID, phoneNumber: PHONE });
    t.db.seed("customers", UID, { uid: UID, phone: PHONE });
    t.db.seed("users", UID, { uid: UID, phone: PHONE });
    t.db.seed("bookings", "b1", { phone: PHONE, customer: { uid: UID, phone: PHONE } });
    t.db.seed("bookings", "b2", { agent: { uid: UID, phone: PHONE } });
    t.db.seed("auto-assignment_requests", "a1", { customer: { uid: UID, phone: PHONE } });
    t.db.seed("tipping", UID, { agentPhone: PHONE });
  });

  it("updates every copy of the number and keeps the UID", async () => {
    const { verificationId } = await t.service.handleRequestOtp(changeRequest());
    const result = await t.service.handleVerifyOtp(confirm(verificationId, sentCode(t.sms)));

    assert.equal(result.phone, NEW_PHONE);
    assert.equal(t.auth.users.get(UID).phoneNumber, NEW_PHONE);
    assert.equal(t.db.read("customers", UID).phone, NEW_PHONE);
    assert.equal(t.db.read("users", UID).phone, NEW_PHONE);
    assert.equal(t.db.read("bookings", "b1").customer.phone, NEW_PHONE);
    assert.equal(t.db.read("bookings", "b1").phone, NEW_PHONE);
    assert.equal(t.db.read("bookings", "b2").agent.phone, NEW_PHONE);
    assert.equal(t.db.read("auto-assignment_requests", "a1").customer.phone, NEW_PHONE);
    assert.equal(t.db.read("tipping", UID).agentPhone, NEW_PHONE);
    assert.equal(t.otpDb.read("phoneChanges", UID).status, STATUS.COMPLETE);
  });

  it("updates admin docs using their own field names", async () => {
    t.db.seed("admins", UID, { phoneNumber: PHONE });
    const { verificationId } = await t.service.handleRequestOtp(changeRequest());
    await t.service.handleVerifyOtp(confirm(verificationId, sentCode(t.sms)));
    assert.equal(t.db.read("admins", UID).phoneNumber, NEW_PHONE);
    assert.equal(t.db.read("admins", UID).phone, undefined);
  });

  it("refuses anonymous sessions", async () => {
    const auth = { ...sessionFor(UID), token: { firebase: { sign_in_provider: "anonymous" } } };
    await rejectsWith(t.service.handleRequestOtp(changeRequest({ auth })), "requires-recent-login");
    assert.equal(t.sms.sent.length, 0);
  });

  it("refuses a session for a different account than the app expects", async () => {
    const data = { phone: NEW_PHONE, purpose: "change_phone", expectedUid: "someone-else" };
    await rejectsWith(t.service.handleRequestOtp(changeRequest({ data })), "requires-recent-login");
  });

  it("refuses revoked sessions", async () => {
    t.auth.verifyIdToken = async () => {
      throw new Error("revoked");
    };
    await rejectsWith(t.service.handleRequestOtp(changeRequest()), "requires-recent-login");
  });

  it("refuses a code requested by another account", async () => {
    t.auth.add({ uid: "u2", phoneNumber: "+966522222222" });
    const { verificationId } = await t.service.handleRequestOtp(changeRequest());
    await rejectsWith(
      t.service.handleVerifyOtp({
        auth: sessionFor("u2"),
        data: { verificationId, code: sentCode(t.sms), requestId: REQUEST_ID, expectedUid: "u2" },
      }),
      "session-expired",
    );
    assert.equal(t.auth.users.get(UID).phoneNumber, PHONE);
  });

  it("refuses a number used by another profile", async () => {
    t.db.seed("users", "u2", { phone: NEW_PHONE });
    await rejectsWith(t.service.handleRequestOtp(changeRequest()), "phone-already-in-use");
    assert.equal(t.sms.sent.length, 0);
  });

  it("refuses a number invited as an admin", async () => {
    t.db.seed("pending_admins", "invite", { phoneNumber: NEW_PHONE });
    await rejectsWith(t.service.handleRequestOtp(changeRequest()), "phone-already-in-use");
  });

  it("refuses a number held by an account with bookings", async () => {
    t.auth.add({ uid: "u2", phoneNumber: NEW_PHONE });
    t.db.seed("bookings", "b3", { customer: { uid: "u2" } });
    await rejectsWith(t.service.handleRequestOtp(changeRequest()), "phone-already-in-use");
  });

  it("takes over a number held by an empty orphan account", async () => {
    t.auth.add({ uid: "orphan", phoneNumber: NEW_PHONE });
    const { verificationId } = await t.service.handleRequestOtp(changeRequest());
    await t.service.handleVerifyOtp(confirm(verificationId, sentCode(t.sms)));
    assert.equal(t.auth.users.get(UID).phoneNumber, NEW_PHONE);
    assert.equal(t.auth.users.get("orphan").phoneNumber, null);
    assert.equal(t.auth.users.get("orphan").disabled, true);
  });

  it("restores profiles if the Auth update fails", async () => {
    const { verificationId } = await t.service.handleRequestOtp(changeRequest());
    t.auth.failUpdate = new Error("auth down");
    await rejectsWith(
      t.service.handleVerifyOtp(confirm(verificationId, sentCode(t.sms))),
      "internal-error",
    );
    assert.equal(t.auth.users.get(UID).phoneNumber, PHONE);
    assert.equal(t.db.read("customers", UID).phone, PHONE);
    assert.equal(t.db.read("users", UID).phone, PHONE);
    assert.equal(t.otpDb.read("phoneChanges", UID).status, STATUS.FAILED);
    assert.equal(t.otpDb.read("phoneChanges", UID).open, false);
  });

  it("writes profiles before moving the Auth number", async () => {
    const { verificationId } = await t.service.handleRequestOtp(changeRequest());
    let profileAtAuthUpdate = null;
    const updateUser = t.auth.updateUser;
    t.auth.updateUser = async (uid, update) => {
      profileAtAuthUpdate = t.db.read("customers", UID).phone;
      return updateUser(uid, update);
    };
    await t.service.handleVerifyOtp(confirm(verificationId, sentCode(t.sms)));
    assert.equal(profileAtAuthUpdate, NEW_PHONE);
  });

  it("answers a retry after the first response was lost", async () => {
    const { verificationId } = await t.service.handleRequestOtp(changeRequest());
    const code = sentCode(t.sms);
    await t.service.handleVerifyOtp(confirm(verificationId, code));
    const retry = await t.service.handleVerifyOtp(confirm(verificationId, code));
    assert.equal(retry.phone, NEW_PHONE);
  });

  it("sweeper finishes a change interrupted before the Auth update", async () => {
    t.otpDb.seed("phoneChanges", UID, {
      ...t.phoneChange.buildJournal({ uid: UID, oldPhone: PHONE, newPhone: NEW_PHONE, challengeId: "c" }),
    });
    t.advance(4 * 60 * 1000);
    await t.phoneChange.sweep();
    assert.equal(t.auth.users.get(UID).phoneNumber, NEW_PHONE);
    assert.equal(t.db.read("customers", UID).phone, NEW_PHONE);
    assert.equal(t.otpDb.read("phoneChanges", UID).status, STATUS.COMPLETE);
  });

  it("sweeper leaves a change that may still be running", async () => {
    t.otpDb.seed("phoneChanges", UID, {
      ...t.phoneChange.buildJournal({ uid: UID, oldPhone: PHONE, newPhone: NEW_PHONE, challengeId: "c" }),
    });
    await t.phoneChange.sweep();
    assert.equal(t.auth.users.get(UID).phoneNumber, PHONE);
  });
});
