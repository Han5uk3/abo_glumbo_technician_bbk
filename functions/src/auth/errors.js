"use strict";

const { HttpsError } = require("firebase-functions/v2/https");

// `details.code` is what the apps read. The values match the FirebaseAuthException
// codes their screens already translate, so existing error messages keep working.
// Nothing here may map to `unauthenticated`: the apps treat that as a stale
// session and retry the call once after signing out.
const HTTPS_CODES = Object.freeze({
  "invalid-phone-number": "invalid-argument",
  "invalid-verification-code": "invalid-argument",
  "session-expired": "failed-precondition",
  "too-many-requests": "resource-exhausted",
  "quota-exceeded": "resource-exhausted",
  "requires-recent-login": "failed-precondition",
  "phone-already-in-use": "already-exists",
  "user-disabled": "permission-denied",
  "internal-error": "internal",
});

function otpError(appCode, extra = {}) {
  const httpsCode = HTTPS_CODES[appCode] || "internal";
  return new HttpsError(httpsCode, appCode, { code: appCode, ...extra });
}

module.exports = { otpError };
