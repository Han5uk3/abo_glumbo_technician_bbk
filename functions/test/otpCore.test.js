"use strict";

const assert = require("node:assert/strict");
const { describe, it } = require("node:test");

const core = require("../src/auth/otpCore");
const { sendSms, toRecipient } = require("../src/auth/taqnyat");

const HMAC = "a".repeat(64);

describe("phone validation", () => {
  it("accepts only Saudi mobile numbers", () => {
    assert.equal(core.isSaudiMobile("+966555724363"), true);
    assert.equal(core.isSaudiMobile("+966112345678"), false);
    assert.equal(core.isSaudiMobile("0555724363"), false);
    assert.equal(core.isSaudiMobile("+9665557243631"), false);
  });

  it("masks numbers in logs", () => {
    assert.equal(core.maskPhone("+966555724363"), "+9665*****63");
  });
});

describe("code generation", () => {
  it("keeps leading zeros", () => {
    assert.equal(core.generateCode(() => 42), "000042");
  });
});

describe("reserved accounts", () => {
  it("always treats the core admin number as reserved", () => {
    assert.equal(core.isReserved("+966501234567", {}), true);
  });

  it("rejects malformed secrets instead of ignoring them", () => {
    for (const raw of ["", "not json", "[]", "null", '{"+966501234567":{"uid":""}}']) {
      assert.throws(() => core.parseReservedAccounts(raw));
    }
    assert.throws(() =>
      core.parseReservedAccounts(JSON.stringify({ "123": { uid: "u", codeHmac: HMAC } })),
    );
  });

  it("parses a valid secret", () => {
    const parsed = core.parseReservedAccounts(
      JSON.stringify({ "+966501234567": { uid: "u1", codeHmac: HMAC } }),
    );
    assert.equal(parsed["+966501234567"].uid, "u1");
  });

  it("locks after repeated failures", () => {
    let guard = {};
    for (let i = 0; i < core.RESERVED_MAX_FAILURES; i += 1) {
      guard = core.nextReservedGuard(guard, 1000);
    }
    assert.equal(guard.lockedUntilMs, 1000 + core.RESERVED_LOCK_MS);
  });
});

describe("client IP", () => {
  it("ignores a forged left-most hop", () => {
    assert.equal(core.clientIp({ "x-forwarded-for": "1.1.1.1, 203.0.113.9" }), "203.0.113.9");
  });

  it("skips private proxy hops", () => {
    assert.equal(core.clientIp({ "x-forwarded-for": "203.0.113.9, 10.0.0.1" }), "203.0.113.9");
  });

  it("uses the fallback without a header", () => {
    assert.equal(core.clientIp({}, "198.51.100.1"), "198.51.100.1");
  });
});

describe("send limits", () => {
  it("enforces the cooldown", () => {
    const first = core.checkPhoneSend(undefined, 1000);
    assert.equal(first.allowed, true);
    const second = core.checkPhoneSend(first.next, 1000 + 30000);
    assert.equal(second.allowed, false);
    assert.equal(second.retryAfterSeconds, 30);
  });

  it("enforces the hourly and daily caps", () => {
    let state;
    let nowMs = 0;
    for (let i = 0; i < core.PHONE_LIMITS.perHour; i += 1) {
      nowMs += core.PHONE_LIMITS.cooldownMs;
      state = core.checkPhoneSend(state, nowMs).next;
    }
    nowMs += core.PHONE_LIMITS.cooldownMs;
    assert.equal(core.checkPhoneSend(state, nowMs).allowed, false);

    const fullDay = { dayStartMs: 1, dayCount: core.PHONE_LIMITS.perDay };
    assert.equal(core.checkPhoneSend(fullDay, core.HOUR_MS * 2).allowed, false);
  });

  it("refunds a failed send", () => {
    const sent = core.checkPhoneSend({ lastSentAtMs: 5 }, core.DAY_MS).next;
    assert.deepEqual(core.refundPhoneSend(sent), { lastSentAtMs: 5, hourCount: 0, dayCount: 0 });
  });

  it("resets a window after it passes", () => {
    const full = { startMs: 1, count: 3 };
    assert.equal(core.checkWindow(full, 2, core.HOUR_MS, 3).allowed, false);
    assert.equal(core.checkWindow(full, core.HOUR_MS + 2, core.HOUR_MS, 3).allowed, true);
  });
});

describe("verification decisions", () => {
  const active = { id: "c1", status: "active", attempts: 0, expiresAtMs: 5000 };
  const base = {
    challenge: active,
    activeChallengeId: "c1",
    expectedHmac: HMAC,
    suppliedHmac: HMAC,
    requestId: "request-1",
    nowMs: 1000,
  };

  it("accepts the right code", () => {
    assert.equal(core.decideVerification(base).outcome, "ok");
  });

  it("counts a wrong code", () => {
    const result = core.decideVerification({ ...base, suppliedHmac: "b".repeat(64) });
    assert.deepEqual(result, { outcome: "invalid", attempts: 1 });
  });

  it("locks after the attempt limit, even with the right code", () => {
    const challenge = { ...active, attempts: core.MAX_ATTEMPTS };
    assert.equal(core.decideVerification({ ...base, challenge }).outcome, "locked");
  });

  it("rejects expired and superseded challenges", () => {
    assert.equal(core.decideVerification({ ...base, nowMs: 5000 }).outcome, "expired");
    assert.equal(core.decideVerification({ ...base, activeChallengeId: "c2" }).outcome, "expired");
    assert.equal(core.decideVerification({ ...base, challenge: null }).outcome, "expired");
  });

  it("honours a reserved number lock", () => {
    assert.equal(core.decideVerification({ ...base, lockedUntilMs: 2000 }).outcome, "locked");
  });

  it("re-mints only for the same request inside the window", () => {
    const consumed = {
      ...active,
      status: "consumed",
      consumedRequestId: "request-1",
      remintUntilMs: 2000,
    };
    assert.equal(core.decideVerification({ ...base, challenge: consumed }).outcome, "remint");
    assert.equal(
      core.decideVerification({ ...base, challenge: consumed, requestId: "other" }).outcome,
      "expired",
    );
    assert.equal(
      core.decideVerification({ ...base, challenge: consumed, nowMs: 2000 }).outcome,
      "expired",
    );
  });

  it("never treats a missing reserved hash as a match", () => {
    const result = core.decideVerification({ ...base, expectedHmac: null, suppliedHmac: null });
    assert.equal(result.outcome, "invalid");
  });
});

describe("challenge binding", () => {
  const input = { code: "123456", challengeId: "c1", phone: "+966555724363", purpose: "login", uid: null };

  it("changes when any bound value changes", () => {
    const original = core.challengeHmac("pepper", input);
    assert.notEqual(core.challengeHmac("pepper", { ...input, challengeId: "c2" }), original);
    assert.notEqual(core.challengeHmac("pepper", { ...input, purpose: "change_phone" }), original);
    assert.notEqual(core.challengeHmac("pepper", { ...input, uid: "u1" }), original);
    assert.notEqual(core.challengeHmac("other", input), original);
  });
});

describe("SMS text", () => {
  for (const app of [core.APP_CUSTOMER, core.APP_TECHNICIAN, null]) {
    for (const locale of ["ar", "en", "ur"]) {
      it(`${app} ${locale} has exactly one 6-digit code and fits one segment`, () => {
        const body = core.smsBody("123456", locale, app);
        assert.deepEqual(body.match(/\b\d{6}\b/g), ["123456"]);
        assert.ok(body.length <= (locale === "en" ? 160 : 70), `length ${body.length}`);
      });
    }
  }

  it("names the app that asked", () => {
    assert.match(core.smsBody("123456", "en", core.APP_CUSTOMER), /Aboglumbo Tools/);
    assert.match(core.smsBody("123456", "ar", core.APP_TECHNICIAN), /Aboglumbo Technician/);
    assert.match(core.smsBody("123456", "ur", null), /Aboglumbo /);
  });

  it("prefers the App Check identity over the client's claim", () => {
    const technicianAndroid = "1:629201660527:android:2e4177f0e86629d12dfb9a";
    assert.equal(core.resolveApp(technicianAndroid, "customer"), core.APP_TECHNICIAN);
    assert.equal(core.resolveApp(undefined, "customer"), core.APP_CUSTOMER);
    assert.equal(core.resolveApp("1:0:android:unknown", "technician"), core.APP_TECHNICIAN);
    assert.equal(core.resolveApp(undefined, "admin"), null);
    assert.equal(core.resolveApp(undefined, undefined), null);
  });

  it("defaults unknown languages to Arabic", () => {
    assert.equal(core.normalizeLocale("fr"), "ar");
    assert.equal(core.normalizeLocale("en_US"), "en");
  });
});

describe("Taqnyat client", () => {
  const send = (status, payload) =>
    sendSms({
      token: "token",
      sender: "Sender",
      phone: "+966555724363",
      body: "text",
      fetchImpl: async () => ({ status, json: async () => payload }),
    });

  it("sends recipients without a plus sign", async () => {
    assert.equal(toRecipient("+966555724363"), "966555724363");
    let request;
    await sendSms({
      token: "token",
      sender: "Sender",
      phone: "+966555724363",
      body: "text",
      fetchImpl: async (url, options) => {
        request = { url, options };
        return { status: 201, json: async () => ({ messageId: 1 }) };
      },
    });
    assert.equal(request.url, "https://api.taqnyat.sa/v1/messages");
    assert.equal(request.options.headers.Authorization, "Bearer token");
    assert.deepEqual(JSON.parse(request.options.body), {
      recipients: ["966555724363"],
      body: "text",
      sender: "Sender",
    });
  });

  it("reports success", async () => {
    const result = await send(201, { messageId: 7, accepted: "[966555724363,]", rejected: "[]" });
    assert.deepEqual(result, { status: "sent", messageId: 7 });
  });

  it("treats a 201 that rejects the number as a failure", async () => {
    const result = await send(201, { accepted: "[]", rejected: "[966555724363,]" });
    assert.equal(result.status, "failed");
    assert.equal(result.appCode, "invalid-phone-number");
  });

  it("maps balance errors and raises an alert", async () => {
    const result = await send(400, { code: 3 });
    assert.equal(result.appCode, "quota-exceeded");
    assert.equal(result.alert, true);
  });

  it("maps credential errors to an internal error", async () => {
    const result = await send(401, { statusCode: 401, message: "invalid credentials information" });
    assert.equal(result.appCode, "internal-error");
    assert.equal(result.alert, true);
  });

  it("reads error codes from the HTTP 200 failure envelope", async () => {
    const envelope = (code) => ({
      status: 1,
      ResponseStatus: "fail",
      Data: null,
      Error: { ErrorCode: code, MessageEn: "reason" },
    });
    const balance = await send(200, envelope(3));
    assert.equal(balance.status, "failed");
    assert.equal(balance.appCode, "quota-exceeded");
    assert.equal(balance.providerMessage, "reason");
    assert.equal((await send(200, envelope(15))).appCode, "invalid-phone-number");
  });

  it("raises an alert when the server IP is not authorized", async () => {
    const message = " this ip  203.0.113.9 Not authorized to using the API";
    for (const result of [
      await send(403, { statusCode: 403, message }),
      await send(200, { ResponseStatus: "fail", Error: { ErrorCode: 102, MessageEn: message } }),
    ]) {
      assert.equal(result.status, "failed");
      assert.equal(result.appCode, "internal-error");
      assert.equal(result.alert, true);
      assert.equal(result.providerMessage, message.trim());
    }
  });

  it("treats server errors as ambiguous", async () => {
    assert.equal((await send(503, {})).status, "ambiguous");
  });

  it("treats a timeout as ambiguous", async () => {
    const result = await sendSms({
      token: "token",
      sender: "Sender",
      phone: "+966555724363",
      body: "text",
      fetchImpl: async () => {
        throw Object.assign(new Error("timed out"), { name: "TimeoutError" });
      },
    });
    assert.deepEqual(result, { status: "ambiguous", reason: "TimeoutError" });
  });
});
