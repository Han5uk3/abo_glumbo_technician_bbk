const fs = require('fs');
const filePath = 'c:/Hansuke/Work/abo_glumbo_technician_bbk/functions/src/triggers/bookingTriggers.js';
let data = fs.readFileSync(filePath, 'utf8');

const targetStr = \        // Skip if technician previously cancelled this booking
        if (cancelledWorkerUids.includes(techUid)) {
          continue;
        }

        const techCoords = extractTechnicianCoordinates(tech);
        if (!techCoords) continue;
        const techLat = techCoords.lat;
        const techLon = techCoords.lon;

        const distance = calculateDistanceKm(techLat, techLon, custLat, custLon);
        if (distance > 60.0) continue;

        // Active booking check
        const activeBookings = await db.collection("bookings")
          .where("agent.uid", "==", techUid)
          .where("bookingStatusCode", "==", "A")
          .get();

        let hasStartedJob = false;
        for (const bookingDoc of activeBookings.docs) {
          const bData = bookingDoc.data();
          if (bData.trackingStartedAt && !bData.completedAt && !bData.cancelledAt) {
            hasStartedJob = true;
            break;
          }
        }

        if (hasStartedJob) continue;\;

const replacementStr = \        // Skip if technician previously cancelled this booking
        if (cancelledWorkerUids.includes(techUid)) {
          continue;
        }

        // Job Role Check
        const categoryId = request.service?.category;
        const techJobRoles = tech.jobRoles || [];
        if (categoryId && !techJobRoles.includes(categoryId)) {
          continue;
        }

        const techCoords = extractTechnicianCoordinates(tech);
        if (!techCoords) continue;
        const techLat = techCoords.lat;
        const techLon = techCoords.lon;

        const distance = calculateDistanceKm(techLat, techLon, custLat, custLon);
        if (distance > 60.0) continue;

        // Active booking & Time Conflict check
        const activeBookings = await db.collection("bookings")
          .where("agent.uid", "==", techUid)
          .where("bookingStatusCode", "==", "A")
          .get();

        let hasStartedJob = false;
        let hasTimeConflict = false;
        const reqBookingTime = request.bookingDateTime ? request.bookingDateTime.toMillis() : null;

        for (const bookingDoc of activeBookings.docs) {
          const bData = bookingDoc.data();
          if (bData.trackingStartedAt && !bData.completedAt && !bData.cancelledAt) {
            hasStartedJob = true;
          }
          if (reqBookingTime && bData.bookingDateTime) {
            if (bData.bookingDateTime.toMillis() === reqBookingTime) {
              hasTimeConflict = true;
            }
          }
        }

        if (hasStartedJob || hasTimeConflict) continue;\;

// Convert line endings for target match since git might check out as CRLF or LF
const normalize = (s) => s.replace(/\r\n/g, '\n');
data = normalize(data);

if (data.includes(normalize(targetStr))) {
  data = data.replace(normalize(targetStr), normalize(replacementStr));
  fs.writeFileSync(filePath, data);
  console.log('Successfully replaced chunk 3');
} else {
  console.log('Target string not found in file!');
}
