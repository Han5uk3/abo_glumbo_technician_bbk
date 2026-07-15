const admin = require("firebase-admin");
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

function sendAndStoreNotification({
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
}) {
  let collectionName = "users";
  if (targetRole === "customer") {
    collectionName = "customers";
  } else if (targetRole === "admin") {
    collectionName = "admins";
  }

  if (data?.type !== "chat") {
    const requestId = data?.requestId || data?.offerId;
    let query = admin.firestore().collection(collectionName).doc(targetId).collection("notifications")
      .where("titleEn", "==", titleEn)
      .where("bodyEn", "==", bodyEn);

    if (requestId) {
      query = query.where("data.requestId", "==", requestId);
    }

    try {
      return query.get().then(existing => {
        if (!existing.empty) {
          console.log(`Duplicate notification detected for ${targetRole} ${targetId} with requestId ${requestId}, skipping`);
          return null;
        }
        return proceedToSend(collectionName, targetId, targetRole, titleEn, titleAr, titleUr, bodyEn, bodyAr, bodyUr, data, fcmToken, lanCode);
      }).catch(error => {
        console.error(`Error checking for duplicate notification:`, error);
        return proceedToSend(collectionName, targetId, targetRole, titleEn, titleAr, titleUr, bodyEn, bodyAr, bodyUr, data, fcmToken, lanCode);
      });
    } catch (error) {
      console.error(`Error checking for duplicate notification:`, error);
    }
  }

  return proceedToSend(collectionName, targetId, targetRole, titleEn, titleAr, titleUr, bodyEn, bodyAr, bodyUr, data, fcmToken, lanCode);
}

async function proceedToSend(collectionName, targetId, targetRole, titleEn, titleAr, titleUr, bodyEn, bodyAr, bodyUr, data, fcmToken, lanCode) {
  try {
    await admin
      .firestore()
      .collection(collectionName)
      .doc(targetId)
      .collection("notifications")
      .add({
        titleEn,
        titleAr,
        titleUr: titleUr || "",
        bodyEn,
        bodyAr,
        bodyUr: bodyUr || "",
        data: data || {},
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    console.log(`Notification stored for ${targetRole} ${targetId}`);
  } catch (e) {
    console.error(
      `Error storing notification for ${targetRole} ${targetId}:`,
      e
    );
  }

  if (fcmToken && fcmToken.trim() !== "") {
    const title = lanCode === "ar"
      ? (titleAr || titleEn)
      : lanCode === "ur"
        ? (titleUr || titleAr || titleEn)
        : titleEn;
    const body = lanCode === "ar"
      ? (bodyAr || bodyEn)
      : lanCode === "ur"
        ? (bodyUr || bodyAr || bodyEn)
        : bodyEn;

    const message = {
      notification: { title, body },
      android: {
        priority: "high",
        notification: {
          channelId: "abo_glumbo_channel",
          priority: "high",
          defaultSound: true,
          defaultVibrateTimings: true,
          defaultLightSettings: true,
          visibility: "public",
          notificationPriority: "PRIORITY_HIGH",
        },
      },
      data: {
        ...data,
        lanCode: lanCode || "en",
        title: title,
        body: body,
      },
      token: fcmToken,
    };

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
