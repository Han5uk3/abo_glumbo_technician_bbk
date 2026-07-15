const admin = require('firebase-admin');
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

  // 1. First attempt: Find the address by selectedAddressId
  if (selectedAddressId && addresses.length > 0) {
    const selectedAddr = addresses.find(addr => addr.id === selectedAddressId);
    if (selectedAddr) {
      lat = parseVal(selectedAddr.lat !== undefined && selectedAddr.lat !== null ? selectedAddr.lat : selectedAddr.latitude);
      lon = parseVal(selectedAddr.lon !== undefined && selectedAddr.lon !== null ? selectedAddr.lon : selectedAddr.longitude);
    }
  }

  // 2. Second attempt: Find the address where isSelected is true
  if ((lat === null || isNaN(lat) || lon === null || isNaN(lon)) && addresses.length > 0) {
    const selectedAddr = addresses.find(addr => addr.isSelected === true || addr.isSelected === 'true');
    if (selectedAddr) {
      lat = parseVal(selectedAddr.lat !== undefined && selectedAddr.lat !== null ? selectedAddr.lat : selectedAddr.latitude);
      lon = parseVal(selectedAddr.lon !== undefined && selectedAddr.lon !== null ? selectedAddr.lon : selectedAddr.longitude);
    }
  }

  // 3. Third attempt: Default to first address in the customer's list
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
  targetRole, // 'customer', 'technician', 'admin'
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
}

module.exports.sendAndStoreNotification = sendAndStoreNotification;

function getAllAdminUsers() {
  try {
    // The source of truth for admins is now the dedicated 'admins' collection.
    const adminsSnapshot = await admin
      .firestore()
      .collection("admins")
      .get();

    const adminUsersMap = new Map();

    adminsSnapshot.forEach((doc) => {
      const data = doc.data();
      const level = data.accessLevel;

      // Per USER request: Only access level 1 or 2 needs to get notifications.
      // However, accessLevel 0 is Super Admin and should also receive them.
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
    const selectedAddr = addresses.find(addr => addr.isSelected === true || addr.isSelected === 'true');
    if (selectedAddr) return selectedAddr;
  }

  if (addresses.length > 0) {
    return addresses[0];
  }

  return null;
}

module.exports.extractCustomerAddress = extractCustomerAddress;

