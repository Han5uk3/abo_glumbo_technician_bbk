"use strict";

// Taqnyat SMS client. https://dev.taqnyat.sa/ar/doc/sms/

const TAQNYAT_MESSAGES_URL = "https://api.taqnyat.sa/v1/messages";
const SEND_TIMEOUT_MS = 8000;

const BALANCE_ERRORS = new Set([2, 3]);
const BAD_NUMBER_ERROR = 15;

/** Taqnyat wants international format with no leading + or 00. */
function toRecipient(phone) {
  return phone.replace(/^\+/, "");
}

function listsRecipient(field, recipient) {
  if (field === undefined || field === null) return false;
  const text = Array.isArray(field) ? field.join(",") : String(field);
  return text.includes(recipient);
}

/**
 * Taqnyat reports errors in more than one shape. Seen live:
 * HTTP 200 `{"ResponseStatus":"fail","Error":{"ErrorCode":102,"MessageEn":"..."}}`
 * HTTP 403 `{"statusCode":403,"message":"..."}`
 */
function errorCodeOf(body) {
  const candidates = [body?.Error?.ErrorCode, body?.code, body?.errorCode, body?.error];
  for (const candidate of candidates) {
    const parsed = Number.parseInt(candidate, 10);
    if (Number.isInteger(parsed)) return parsed;
  }
  return null;
}

function errorMessageOf(body) {
  const message = body?.Error?.MessageEn ?? body?.message;
  return typeof message === "string" ? message.trim().slice(0, 200) : null;
}

function failure(httpStatus, providerCode, providerMessage = null) {
  const details = { status: "failed", httpStatus, providerCode, providerMessage };
  if (BALANCE_ERRORS.has(providerCode)) {
    return { ...details, appCode: "quota-exceeded", alert: true };
  }
  if (providerCode === BAD_NUMBER_ERROR) {
    return { ...details, appCode: "invalid-phone-number", alert: false };
  }
  if (httpStatus === 429) {
    return { ...details, appCode: "too-many-requests", alert: true };
  }
  // Sender, credential, IP and account problems: users cannot fix these.
  return { ...details, appCode: "internal-error", alert: true };
}

/**
 * Sends one SMS and never throws. Returns one of:
 * - `sent`: Taqnyat accepted the message.
 * - `failed`: definitely not sent, so the caller may refund the user's quota.
 * - `ambiguous`: a timeout or server error. The SMS may still arrive, so the
 *   caller must keep the code valid and must not retry automatically.
 */
async function sendSms({
  token,
  sender,
  phone,
  body,
  fetchImpl = fetch,
  timeoutMs = SEND_TIMEOUT_MS,
}) {
  const recipient = toRecipient(phone);
  let response;
  try {
    response = await fetchImpl(TAQNYAT_MESSAGES_URL, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ recipients: [recipient], body, sender }),
      signal: AbortSignal.timeout(timeoutMs),
    });
  } catch (error) {
    return { status: "ambiguous", reason: error?.name || "network" };
  }

  let payload = null;
  try {
    payload = await response.json();
  } catch (_) {
    payload = null;
  }

  if (response.status === 201) {
    if (listsRecipient(payload?.rejected, recipient)) {
      return failure(201, BAD_NUMBER_ERROR);
    }
    return { status: "sent", messageId: payload?.messageId ?? null };
  }
  if (response.status >= 500) {
    return { status: "ambiguous", reason: `http_${response.status}` };
  }
  return failure(response.status, errorCodeOf(payload), errorMessageOf(payload));
}

module.exports = { TAQNYAT_MESSAGES_URL, sendSms, toRecipient };
