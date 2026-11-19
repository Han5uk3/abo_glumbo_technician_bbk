"use strict";

// Deployed entry points for Taqnyat OTP login. Must be required after
// admin.initializeApp().

const admin = require("firebase-admin");
const { getFirestore } = require("firebase-admin/firestore");
const { logger } = require("firebase-functions/v2");
const { defineInt, defineSecret, defineString } = require("firebase-functions/params");
const { onCall } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");

const { otpError } = require("./errors");
const { parseReservedAccounts } = require("./otpCore");
const { createOtpService } = require("./otpService");
const { createPhoneChangeService } = require("./phoneChange");
const { sendSms } = require("./taqnyat");

const FUNCTION_REGION = "europe-west1";
const OTP_DATABASE_ID = "auth-otp";
// Only these functions may sign custom tokens, not the project's other functions.
const OTP_SERVICE_ACCOUNT = "otp-auth@worker-app-tnext.iam.gserviceaccount.com";
// Taqnyat only accepts calls from allowlisted IPs. This connector sends traffic
// through the Cloud NAT that owns our static IP (scripts/setupOtpInfra.sh).
const OTP_VPC_CONNECTOR = "otp-egress";

const TAQ_API = defineSecret("TAQ_API");
const OTP_PEPPER = defineSecret("OTP_PEPPER");
const OTP_RESERVED_ACCOUNTS = defineSecret("OTP_RESERVED_ACCOUNTS");

const TAQ_SENDNAME = defineString("TAQ_SENDNAME", {
  default: "TAQ_SENDNAME",
  description: "Approved Taqnyat sender name (case sensitive)",
});
const OTP_GLOBAL_HOURLY_LIMIT = defineInt("OTP_GLOBAL_HOURLY_LIMIT", { default: 600 });
const OTP_UNATTESTED_HOURLY_LIMIT = defineInt("OTP_UNATTESTED_HOURLY_LIMIT", { default: 120 });
const OTP_IP_HOURLY_LIMIT = defineInt("OTP_IP_HOURLY_LIMIT", { default: 30 });

/** A value still set to its placeholder name counts as not configured. */
function configured(value, placeholder) {
  const trimmed = (value || "").trim();
  return trimmed && trimmed !== placeholder ? trimmed : null;
}

function getConfig() {
  const pepper = configured(OTP_PEPPER.value(), "OTP_PEPPER");
  let reserved;
  try {
    reserved = parseReservedAccounts(OTP_RESERVED_ACCOUNTS.value());
  } catch (error) {
    logger.error("otp_reserved_secret_invalid", {
      alert: "otp_config_invalid",
      error: error.message,
    });
    throw otpError("internal-error");
  }
  if (!pepper) {
    logger.error("otp_pepper_missing", { alert: "otp_config_invalid" });
    throw otpError("internal-error");
  }
  return {
    pepper,
    reserved,
    taqToken: configured(TAQ_API.value(), "TAQ_API"),
    taqSender: configured(TAQ_SENDNAME.value(), "TAQ_SENDNAME"),
    limits: {
      globalHourly: OTP_GLOBAL_HOURLY_LIMIT.value(),
      unattestedHourly: OTP_UNATTESTED_HOURLY_LIMIT.value(),
      ipHourly: OTP_IP_HOURLY_LIMIT.value(),
    },
  };
}

let services = null;
function getServices() {
  if (services) return services;
  const otpDb = getFirestore(admin.app(), OTP_DATABASE_ID);
  const phoneChange = createPhoneChangeService({
    db: admin.firestore(),
    otpDb,
    auth: admin.auth(),
    logger,
  });
  const otp = createOtpService({
    otpDb,
    auth: admin.auth(),
    phoneChange,
    sendSms,
    getConfig,
    logger,
  });
  services = { otp, phoneChange };
  return services;
}

const callableOptions = {
  region: FUNCTION_REGION,
  serviceAccount: OTP_SERVICE_ACCOUNT,
  secrets: [TAQ_API, OTP_PEPPER, OTP_RESERVED_ACCOUNTS],
  invoker: "public",
  // Monitor mode. Switch to true once release builds are seen to attest.
  enforceAppCheck: false,
  timeoutSeconds: 60,
  memory: "256MiB",
  maxInstances: 20,
};

// Only this function calls Taqnyat, so only this one needs the static IP.
exports.requestOtp = onCall(
  {
    ...callableOptions,
    vpcConnector: OTP_VPC_CONNECTOR,
    vpcConnectorEgressSettings: "ALL_TRAFFIC",
  },
  (request) => getServices().otp.handleRequestOtp(request),
);

exports.verifyOtp = onCall(callableOptions, (request) =>
  getServices().otp.handleVerifyOtp(request),
);

exports.sweepPhoneChanges = onSchedule(
  {
    schedule: "every 5 minutes",
    region: FUNCTION_REGION,
    serviceAccount: OTP_SERVICE_ACCOUNT,
    timeoutSeconds: 300,
    memory: "256MiB",
  },
  () => getServices().phoneChange.sweep(),
);
