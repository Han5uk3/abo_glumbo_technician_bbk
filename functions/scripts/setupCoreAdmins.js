"use strict";

// One-time setup of the two core admin logins. Changes nothing without --apply.
//
//   OTP_PEPPER=<pepper> node scripts/setupCoreAdmins.js --real +9665XXXXXXXX
//   OTP_PEPPER=<pepper> node scripts/setupCoreAdmins.js --real +9665XXXXXXXX --apply
//
// Needs Application Default Credentials for the project. With --apply it prints
// the value for the OTP_RESERVED_ACCOUNTS secret and the reserved login code.
// The code is shown once and is not stored anywhere in readable form.

const admin = require("firebase-admin");
const { generateCode, isSaudiMobile, reservedCodeHmac } = require("../src/auth/otpCore");

const PROJECT_ID = "worker-app-tnext";
const RESERVED_CORE_ADMIN = "+966501234567";
const CORE_ADMIN_FIELDS = Object.freeze({ accessLevel: 2, isCoreAdmin: true });

function argValue(name) {
  const index = process.argv.indexOf(name);
  return index === -1 ? null : process.argv[index + 1];
}

async function findAuthUser(phone) {
  try {
    return await admin.auth().getUserByPhoneNumber(phone);
  } catch (error) {
    if (error.code === "auth/user-not-found") return null;
    throw error;
  }
}

async function setupReservedAdmin(db, apply) {
  let user = await findAuthUser(RESERVED_CORE_ADMIN);
  if (!user) {
    console.log(`${RESERVED_CORE_ADMIN}: no Auth user yet, one will be created`);
    if (!apply) return null;
    user = await admin.auth().createUser({ phoneNumber: RESERVED_CORE_ADMIN });
  }

  const ref = db.collection("admins").doc(user.uid);
  const doc = await ref.get();
  const isReady = doc.exists && doc.data().isCoreAdmin === true && doc.data().accessLevel === 2;
  console.log(`${RESERVED_CORE_ADMIN}: uid ${user.uid}, core admin doc ${isReady ? "ok" : "needs writing"}`);
  if (apply && !isReady) {
    await ref.set(
      {
        uid: user.uid,
        name: doc.data()?.name || "Core Admin",
        email: doc.data()?.email || "core@admin.com",
        phoneNumber: RESERVED_CORE_ADMIN,
        createdAt: doc.data()?.createdAt || admin.firestore.FieldValue.serverTimestamp(),
        ...CORE_ADMIN_FIELDS,
      },
      { merge: true },
    );
  }
  return user.uid;
}

async function setupRealAdmin(db, phone, apply) {
  const existing = await db.collection("admins").where("phoneNumber", "==", phone).limit(1).get();
  if (!existing.empty) {
    console.log(`${phone}: existing admin ${existing.docs[0].id} will be made core admin`);
    if (apply) await existing.docs[0].ref.update(CORE_ADMIN_FIELDS);
    return;
  }
  const pending = await db.collection("pending_admins").where("phoneNumber", "==", phone).limit(1).get();
  if (!pending.empty) {
    console.log(`${phone}: existing invite will be made core admin`);
    if (apply) await pending.docs[0].ref.update(CORE_ADMIN_FIELDS);
    return;
  }
  console.log(`${phone}: invite will be created, promoted on first login`);
  if (apply) {
    await db.collection("pending_admins").add({
      name: "Core Admin",
      email: "",
      phoneNumber: phone,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      ...CORE_ADMIN_FIELDS,
    });
  }
}

async function main() {
  const apply = process.argv.includes("--apply");
  const realPhone = argValue("--real");
  const pepper = process.env.OTP_PEPPER;
  if (!isSaudiMobile(realPhone)) throw new Error("--real must look like +9665XXXXXXXX");
  if (realPhone === RESERVED_CORE_ADMIN) throw new Error("--real must differ from the reserved number");
  if (apply && !pepper) throw new Error("OTP_PEPPER is required with --apply");

  admin.initializeApp({ projectId: PROJECT_ID });
  const db = admin.firestore();

  const uid = await setupReservedAdmin(db, apply);
  await setupRealAdmin(db, realPhone, apply);

  if (!apply) {
    console.log("\nDry run. Re-run with --apply to make these changes.");
    return;
  }
  const code = generateCode();
  const secret = {
    [RESERVED_CORE_ADMIN]: {
      uid,
      codeHmac: reservedCodeHmac(pepper, { phone: RESERVED_CORE_ADMIN, code }),
    },
  };
  console.log(`\nOTP_RESERVED_ACCOUNTS secret value:\n${JSON.stringify(secret)}`);
  console.log(`\nLogin code for ${RESERVED_CORE_ADMIN} (shown once): ${code}`);
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
