const admin = require("firebase-admin");
const crypto = require("crypto");
const db = admin.firestore();

function extractCustomerCoordinates(request) {
  let lat = null;
  let lon = null;

  const selectedAddressId = request.selectedAddressId;
  const addresses = request.customer?.addresses || [];

  const parseVal = (val) => {
    if (val === undefined || val === null) return NaN;
    const num = parseFloat(val);
    return isNaN(num) ? NaN : num;
  };

  if (selectedAddressId && addresses.length > 0) {
    const selectedAddr = addresses.find(addr => addr.id === selectedAddressId);
    if (selectedAddr) {
      lat = parseVal(selectedAddr.lat !== undefined && selectedAddr.lat !== null ? selectedAddr.lat : selectedAddr.latitude);
      lon = parseVal(selectedAddr.lon !== undefined && selectedAddr.lon !== null ? selectedAddr.lon : selectedAddr.longitude);
    }
  }

  if ((lat === null || isNaN(lat) || lon === null || isNaN(lon)) && addresses.length > 0) {
    const selectedAddr = addresses.find(addr => addr.isSelected === true || addr.isSelected === "true");
    if (selectedAddr) {
      lat = parseVal(selectedAddr.lat !== undefined && selectedAddr.lat !== null ? selectedAddr.lat : selectedAddr.latitude);
      lon = parseVal(selectedAddr.lon !== undefined && selectedAddr.lon !== null ? selectedAddr.lon : selectedAddr.longitude);
    }
  }

  if ((lat === null || isNaN(lat) || lon === null || isNaN(lon)) && addresses.length > 0) {
    const firstAddr = addresses[0];
    lat = parseVal(firstAddr.lat !== undefined && firstAddr.lat !== null ? firstAddr.lat : firstAddr.latitude);
    lon = parseVal(firstAddr.lon !== undefined && firstAddr.lon !== null ? firstAddr.lon : firstAddr.longitude);
  }

  if (lat === null || isNaN(lat) || lon === null || isNaN(lon)) {
    return null;
  }
  return { lat, lon };
}
module.exports.extractCustomerCoordinates = extractCustomerCoordinates;

function extractTechnicianCoordinates(tech) {
  const techLoc = tech.liveLocation || tech.lastKnownLocation || tech.last_known_location;
  if (!techLoc) return null;

  const parseVal = (val) => {
    if (val === undefined || val === null) return NaN;
    const num = parseFloat(val);
    return isNaN(num) ? NaN : num;
  };

  const lat = parseVal(techLoc.latitude !== undefined && techLoc.latitude !== null ? techLoc.latitude : techLoc.lat);
  const lon = parseVal(techLoc.longitude !== undefined && techLoc.longitude !== null ? techLoc.longitude : techLoc.lon);

  if (isNaN(lat) || isNaN(lon)) {
    return null;
  }
  return { lat, lon };
}
module.exports.extractTechnicianCoordinates = extractTechnicianCoordinates;

function calculateDistanceKm(lat1, lon1, lat2, lon2) {
  const R = 6371; // km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}
module.exports.calculateDistanceKm = calculateDistanceKm;

/**
 * Saudi riyal, written the way each language writes it.
 *
 * Every amount shown to a user goes through `money()`. The apps are KSA-only,
 * so any other currency marker in a notification body is a copy bug.
 */
const CURRENCY = { en: "SAR", ar: "ر.س", ur: "سعودی ریال" };

function money(amount, lang) {
  return `${amount} ${CURRENCY[lang] || CURRENCY.en}`;
}
module.exports.money = money;
module.exports.CURRENCY = CURRENCY;

/**
 * Stable identity for a notification, used directly as its Firestore document
 * id so a duplicate cannot be written in the first place.
 *
 * The key describes the EVENT - what happened, to which record, for whom -
 * rather than the rendered text. Text is translated, interpolates names and
 * gets reworded, so it is only used as a tie-breaker between two different
 * messages about the same record.
 *
 * Returns null when the payload carries nothing we can confidently key on. The
 * caller then stores without dedup: letting a duplicate through is cheaper than
 * silently swallowing a notification that was never a duplicate.
 */
function buildDedupeKey({ titleEn, data }) {
  const d = data || {};

  // Most specific identifier wins, because a payload usually carries several.
  // messageId before bookingId, or a whole conversation collapses into one
  // notification. offerId before bookingId, or a re-broadcast of an expired
  // offer looks like a duplicate of the original and is never delivered.
  const entityId =
    d.messageId ||
    d.offerId ||
    d.payoutId ||
    d.walletId ||
    d.requestId ||
    d.bookingId ||
    d.chatId;
  const scope = d.type || d.category;

  if (!entityId || !scope) return null;

  // Document ids may not contain "/" and may not match /^__.*__$/. Sanitising
  // each part and joining with "__" keeps both rules satisfied, because `scope`
  // is non-empty and never begins with an underscore.
  const clean = (part) => String(part).replace(/[^A-Za-z0-9_-]/g, "-");
  const parts = [scope, entityId, d.status, d.targetRole, fingerprint(titleEn)];

  return parts.filter(Boolean).map(clean).join("__").slice(0, 400);
}

function fingerprint(value) {
  return crypto
    .createHash("sha1")
    .update(String(value || ""))
    .digest("hex")
    .slice(0, 8);
}

// gRPC status code Firestore returns when create() hits an existing document.
const ALREADY_EXISTS = 6;

function isAlreadyExists(error) {
  return error?.code === ALREADY_EXISTS || /ALREADY_EXISTS/i.test(error?.message || "");
}

/**
 * Stores a notification for one recipient and pushes it to their device.
 *
 * This is the single implementation for the whole codebase - index.js imports
 * it too. It used to be duplicated there, and the two copies drifted into
 * writing different field names and building different FCM payloads.
 */
async function sendAndStoreNotification({
  targetRole, // "customer", "technician", "admin"
  targetId,
  titleEn,
  titleAr,
  titleUr,
  bodyEn,
  bodyAr,
  bodyUr,
  data,
  fcmToken,
  lanCode,
  sendPush = true, // false -> store the entry but skip the push
}) {
  let collectionName = "users";
  if (targetRole === "customer") {
    collectionName = "customers";
  } else if (targetRole === "admin") {
    collectionName = "admins";
  }

  const notifications = admin
    .firestore()
    .collection(collectionName)
    .doc(targetId)
    .collection("notifications");

  // 1. Store in Firestore, deduplicating on the event identity.
  //
  // All three languages live on the one document so the in-app list can render
  // in whatever language the recipient has selected right now - switching
  // language must not require rewriting their history.
  const payload = {
    titleEn,
    titleAr,
    titleUr: titleUr || "",
    bodyEn,
    bodyAr,
    bodyUr: bodyUr || "",
    data: data || {},
    // Both apps read `read` and filter with .where('read', isEqualTo: false).
    // Firestore equality does not match documents that lack the field, so this
    // name has to stay exactly what the clients expect.
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  const dedupeKey = buildDedupeKey({ titleEn, data });

  try {
    if (dedupeKey) {
      // create() is a compare-and-set, so two invocations racing on the same
      // event - a retry, or two triggers reacting to one write - settle into a
      // single document without a query or a composite index.
      await notifications.doc(dedupeKey).create(payload);
    } else {
      await notifications.add(payload);
    }
  } catch (error) {
    if (dedupeKey && isAlreadyExists(error)) {
      console.log(
        `Duplicate notification ${dedupeKey} for ${targetRole} ${targetId}, skipping`
      );
      return null;
    }
    // Storage is best-effort: still push, so the recipient hears about it.
    console.error(
      `Error saving notification to Firestore for ${targetRole} ${targetId}:`,
      error
    );
  }

  // 2. Send FCM Push Notification
  if (!sendPush) {
    console.log(
      `Push suppressed for ${targetRole} ${targetId} (receiver is viewing this chat)`
    );
    return null;
  }

  if (fcmToken && fcmToken.trim() !== "") {
    const title = (lanCode === "ar"
      ? (titleAr || titleEn || titleUr)
      : lanCode === "ur"
        ? (titleUr || titleAr || titleEn)
        : (titleEn || titleAr || titleUr)) || "Notification";

    const body = (lanCode === "ar"
      ? (bodyAr || bodyEn || bodyUr)
      : lanCode === "ur"
        ? (bodyUr || bodyAr || bodyEn)
        : (bodyEn || bodyAr || bodyUr)) || "New Update";

    // Ensure all data payload values are strings (FCM requirement)
    const safeData = { ...data };
    for (const key in safeData) {
      if (safeData[key] === null || safeData[key] === undefined) {
        delete safeData[key];
      } else if (typeof safeData[key] !== 'string') {
        safeData[key] = String(safeData[key]);
      }
    }

    const isCustom = safeData.type === "custom";

    const message = {
      android: {
        priority: "high",
      },
      apns: {
        headers: {
          "apns-priority": "10",
        },
        payload: {
          aps: {
            sound: "default",
            badge: 1,
            "content-available": 1,
          },
        },
      },
      data: {
        ...safeData,
        lanCode: lanCode || "en",
        title: title,
        body: body,
      },
      token: fcmToken,
    };

    if (!isCustom) {
      message.notification = { title, body };
      message.android.notification = {
        channelId: "abo_glumbo_channel",
        priority: "high",
        defaultSound: true,
        defaultVibrateTimings: true,
        defaultLightSettings: true,
        visibility: "public",
        notificationPriority: "PRIORITY_HIGH",
      };
    }

    try {
      const response = await admin.messaging().send(message);
      console.log(`FCM sent to ${targetRole} ${targetId}, msgId: ${response}`);
      return response;
    } catch (e) {
      console.error(`Error sending FCM to ${targetRole} ${targetId}:`, e);
    }
  }
  return null;
}
module.exports.sendAndStoreNotification = sendAndStoreNotification;
module.exports.buildDedupeKey = buildDedupeKey;

async function getAllAdminUsers() {
  try {
    const adminsSnapshot = await admin
      .firestore()
      .collection("admins")
      .get();

    const adminUsersMap = new Map();

    adminsSnapshot.forEach((doc) => {
      const data = doc.data();
      const level = data.accessLevel;

      if (level === 0 || level === 1 || level === 2) {
        adminUsersMap.set(doc.id, doc);
      }
    });

    return Array.from(adminUsersMap.values());
  } catch (error) {
    console.error("Error fetching admin users:", error);
    return [];
  }
}
module.exports.getAllAdminUsers = getAllAdminUsers;

/**
 * Maps recipient documents to the `{ uid, token, lanCode }` shape the
 * notification call sites use.
 *
 * Deliberately keeps recipients whose `fcmToken` is missing or blank. Callers
 * used to filter those out while building the list, but the list drives
 * `sendAndStoreNotification`, which writes the in-app notification document
 * before it pushes - so dropping a tokenless recipient there cost them their
 * notification history as well as the push they were never going to get. The
 * token is optional all the way down: `sendAndStoreNotification` stores first
 * and simply skips the FCM call when there is nothing to send to.
 */
function toNotificationRecipients(docs) {
  return docs.map((doc) => {
    const data = doc.data();
    return {
      uid: doc.id,
      token: data.fcmToken,
      lanCode: data.lanCode || "en",
    };
  });
}
module.exports.toNotificationRecipients = toNotificationRecipients;

function extractCustomerAddress(request) {
  const selectedAddressId = request.selectedAddressId;
  const addresses = request.customer?.addresses || [];

  if (selectedAddressId && addresses.length > 0) {
    const selectedAddr = addresses.find(addr => addr.id === selectedAddressId);
    if (selectedAddr) return selectedAddr;
  }

  if (addresses.length > 0) {
    const selectedAddr = addresses.find(addr => addr.isSelected === true || addr.isSelected === "true");
    if (selectedAddr) return selectedAddr;
  }

  if (addresses.length > 0) {
    return addresses[0];
  }

  return null;
}
module.exports.extractCustomerAddress = extractCustomerAddress;
