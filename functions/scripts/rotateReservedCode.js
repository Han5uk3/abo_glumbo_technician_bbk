"use strict";

// Issues a new private login code for one reserved number, e.g. when the old
// code is lost. Every other entry in OTP_RESERVED_ACCOUNTS is kept as it is.
//
//   OTP_PEPPER=<pepper> OTP_RESERVED_ACCOUNTS=<current secret JSON> \
//     node scripts/rotateReservedCode.js --out <file> [--phone +9665XXXXXXXX]
//
// Writes the new secret value to <file> and prints the new code once. Then:
//   firebase functions:secrets:set OTP_RESERVED_ACCOUNTS --data-file <file>
//   firebase deploy --only functions:requestOtp,functions:verifyOtp
// and delete <file>. The old code keeps working until that deploy finishes.

const fs = require("fs");
const {
  NEVER_SMS_NUMBERS,
  generateCode,
  hmacEquals,
  parseReservedAccounts,
  reservedCodeHmac,
} = require("../src/auth/otpCore");

function argValue(name) {
  const index = process.argv.indexOf(name);
  return index === -1 ? null : process.argv[index + 1];
}

function main() {
  const pepper = process.env.OTP_PEPPER;
  const current = process.env.OTP_RESERVED_ACCOUNTS;
  const out = argValue("--out");
  const phone = argValue("--phone") || [...NEVER_SMS_NUMBERS][0];
  if (!pepper) throw new Error("OTP_PEPPER is required");
  if (!current) throw new Error("OTP_RESERVED_ACCOUNTS (the current secret value) is required");
  if (!out) throw new Error("--out <file> is required");

  const accounts = { ...parseReservedAccounts(current) };
  const entry = accounts[phone];
  if (!entry) throw new Error(`${phone} is not in OTP_RESERVED_ACCOUNTS`);

  const code = generateCode();
  const codeHmac = reservedCodeHmac(pepper, { phone, code });
  accounts[phone] = { ...entry, codeHmac };

  // Check the result exactly as verifyOtp will read it.
  const written = JSON.stringify(accounts);
  const reread = parseReservedAccounts(written);
  if (!hmacEquals(reread[phone].codeHmac, reservedCodeHmac(pepper, { phone, code }))) {
    throw new Error("self-check failed; nothing written");
  }

  fs.writeFileSync(out, written, { mode: 0o600 });
  console.log(`New secret value written to ${out} (${Object.keys(accounts).length} entries).`);
  console.log(`New login code for ${phone} (shown once): ${code}`);
}

try {
  main();
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
