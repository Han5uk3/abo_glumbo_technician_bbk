const { onDocumentCreated, onDocumentWritten, onDocumentUpdated, onDocumentDeleted } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');
const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;
const { extractCustomerCoordinates, extractTechnicianCoordinates, calculateDistanceKm, sendAndStoreNotification, extractCustomerAddress, getAllAdminUsers } = require('../utils/bookingUtils');

exports.onBookingRequestCreated = onDocumentCreated(
  "booking_request/{requestId}",
  async (event) => {
    const snap = event.data;
    if (!snap) {
      console.log("No data associated with the event");
      return null;
    }

    const request = snap.data();
    const requestId = event.params.requestId;

    const coords = extractCustomerCoordinates(request);
    if (!coords) {
      console.error(`[Booking Request ${requestId}] Missing or invalid customer coordinates`);
      return null;
    }
    const custLat = coords.lat;
    const custLon = coords.lon;
    const customerAddress = extractCustomerAddress(request);

    try {
      // Fetch all online verified technicians (role is technician)
      const techsSnapshot = await db.collection("users")
        .where("role", "==", "technician")
        .where("isOnline", "==", true)
        .where("isVerified", "==", true)
        .get();

      const eligibleTechs = [];
      const rejectedTechs = request.rejectedTechnicians || [];

      for (const doc of techsSnapshot.docs) {
        const tech = doc.data();
        const techUid = doc.id;

        if (rejectedTechs.includes(techUid)) {
          console.log(`[Booking Request ${requestId}] Technician ${techUid} was previously rejected.`);
          continue;
        }

        // 0. Job Role Check
        const categoryId = request.service?.category;
        const techJobRoles = tech.jobRoles || [];
        if (categoryId && !techJobRoles.includes(categoryId)) {
          console.log(`[Booking Request ${requestId}] Technician ${techUid} does not have required job role (category ${categoryId})`);
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

        if (hasStartedJob) {
          console.log(`[Booking Request ${requestId}] Technician ${techUid} has an active started job`);
          continue;
        }

        if (hasTimeConflict) {
          console.log(`[Booking Request ${requestId}] Technician ${techUid} has a conflicting booking for the same date and time`);
          continue;
        }

        eligibleTechs.push({ uid: techUid, data: tech, distance });
      }

      console.log(`[Booking Request ${requestId}] Found ${eligibleTechs.length} eligible technicians`);

      if (eligibleTechs.length === 0) {
        return null;
      }

      const batch = db.batch();
      const expiresAtDate = new Date(Date.now() + 120 * 1000);
      const expiresAtTimestamp = admin.firestore.Timestamp.fromDate(expiresAtDate);

      // Create a job offer for each eligible technician
      for (const tech of eligibleTechs) {
        const offerId = db.collection("job_offers").doc().id;
        const offerRef = db.collection("job_offers").doc(offerId);

        batch.set(offerRef, {
          id: offerId,
          bookingId: requestId, // Document ID and booking ID are the same
          requestId: requestId,
          technicianId: tech.uid,
          status: "pending",
          createdAt: FieldValue.serverTimestamp(),
          expiresAt: expiresAtTimestamp,
          customerName: request.customer?.name || "Customer",
          serviceLocation: {
            fullAddress: customerAddress?.fullName || customerAddress?.streetName || "Service Location",
            streetName: customerAddress?.streetName || "",
            lat: custLat,
            lon: custLon
          },
          serviceName: request.service?.name || "Service",
          serviceNameAr: request.service?.name_ar || request.service?.name || "Service",
          serviceNameUr: request.service?.name_ur || request.service?.name_ar || "Service",
          notes: request.notes || "",
          issueImage: request.issueImage || "",
          issueVideo: request.issueVideo || "",
          bookingDateTime: request.bookingDateTime,
          isRebook: false,
          customerId: request.customer?.uid || ""
        });

        // Send push notification
        if (tech.data.fcmToken && tech.data.fcmToken.trim() !== "") {
          const lan = tech.data.lanCode || "en";
          await sendAndStoreNotification({
            targetRole: "technician",
            targetId: tech.uid,
            titleEn: "New Manual Job Offer",
            titleAr: "عرض حجز يدوي جديد",
            titleUr: "بکنگ کی نئی دستی پیشکش",
            bodyEn: "A new job is available nearby. Tap to accept within 120 seconds.",
            bodyAr: "هناك طلب عمل جديد متاح بالقرب منك. اضغط للقبول خلال 120 ثانية.",
            bodyUr: "قریب ہی ایک نیا کام دستیاب ہے۔ 120 سیکنڈ کے اندر قبول کرنے کے لیے ٹیپ کریں۔",
            data: {
              bookingId: requestId,
              requestId: requestId,
              offerId: offerId,
              targetRole: "technician",
              category: "job_offer",
              type: "job_offer"
            },
            fcmToken: tech.data.fcmToken,
            lanCode: lan
          });
        }
      }

      await batch.commit();
      console.log(`[Booking Request ${requestId}] Broadcast job offers created for ${eligibleTechs.length} technicians`);

    } catch (e) {
      console.error(`Error processing booking request ${requestId}:`, e);
    }

    return null;
  }
);

// 2. Trigger when job offer status is updated
exports.onManualJobOfferUpdated = onDocumentUpdated(
  "job_offers/{offerId}",
  async (event) => {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();

    if (!afterData) return null;

    const offerId = event.params.offerId;
    const bookingId = afterData.bookingId;

    if (!bookingId) return null;

    // Check if status changed to accepted_by_technician
    if (beforeData.status !== "accepted_by_technician" && afterData.status === "accepted_by_technician") {
      const techId = afterData.technicianId;

      try {
        const requestRef = db.collection("booking_request").doc(bookingId);
        const requestSnap = await requestRef.get();

        if (requestSnap.exists) {
          const requestData = requestSnap.data();

          // Check if request is still active/searching
          if (requestData.status === "searching") {
            const techSnap = await db.collection("users").doc(techId).get();

            if (techSnap.exists) {
              const techData = techSnap.data();

              // Fetch all bookings for this technician to count ratings and completed jobs safely without indexes
              const bookingsSnapshot = await db.collection("bookings")
                .where("agent.uid", "==", techId)
                .get();

              let completedJobsCount = 0;
              let totalRating = 0;
              let ratingCount = 0;

              bookingsSnapshot.forEach((doc) => {
                const b = doc.data();
                if (b.bookingStatusCode === "C" && b.paymentCompleted === true) {
                  completedJobsCount++;
                }
                if (b.review && b.review.rating != null) {
                  totalRating += b.review.rating;
                  ratingCount++;
                }
              });

              const averageRating = ratingCount > 0 ? parseFloat((totalRating / ratingCount).toFixed(2)) : (techData.rating || 0.0);

              const techCoords = extractTechnicianCoordinates(techData);
              const custCoords = extractCustomerCoordinates(requestData);
              let distance = null;
              if (techCoords && custCoords) {
                distance = parseFloat(calculateDistanceKm(techCoords.lat, techCoords.lon, custCoords.lat, custCoords.lon).toFixed(1));
              }

              const acceptedTechObject = {
                uid: techId,
                name: techData.name || "Technician",
                phone: techData.phone || "",
                profileUrl: techData.profileUrl || "",
                rating: averageRating,
                completedJobs: completedJobsCount,
                distance: distance,
                acceptedAt: admin.firestore.Timestamp.now()
              };

              // Append to acceptedTechnicians
              await requestRef.update({
                acceptedTechnicians: FieldValue.arrayUnion(acceptedTechObject),
                updatedAt: FieldValue.serverTimestamp()
              });

              // Notify the customer
              const customerId = requestData.customer?.uid;
              if (customerId) {
                const custSnap = await db.collection("customers").doc(customerId).get();
                if (custSnap.exists) {
                  const custData = custSnap.data();
                  if (custData.fcmToken && custData.fcmToken.trim() !== "") {
                    await sendAndStoreNotification({
                      targetRole: "customer",
                      targetId: customerId,
                      titleEn: "Technician Accepted!",
                      titleAr: "قبل الفني العرض!",
                      titleUr: "ٹیکنیشن نے قبول کر لیا!",
                      bodyEn: `${techData.name || "A technician"} has accepted your booking request. Review and complete your booking.`,
                      bodyAr: `لقد قبل الفني ${techData.name || "فني"} طلب الحجز الخاص بك. راجع وأكمل حجزك.`,
                      bodyUr: `ٹیکنیشن ${techData.name || "فنی"} نے آپ کی بکنگ کی درخواست قبول کر لی ہے۔ جائزہ لیں اور اپنی بکنگ مکمل کریں۔`,
                      data: {
                        bookingId: bookingId,
                        category: "manual_accepted",
                        type: "manual_accepted"
                      },
                      fcmToken: custData.fcmToken,
                      lanCode: custData.lanCode || "en"
                    });
                  }
                }
              }

              console.log(`[Offer ${offerId}] Technician ${techId} added to booking_request ${bookingId}`);
            }
          }
        }
      } catch (e) {
        console.error(`Error handling manual job offer acceptance for offer ${offerId}:`, e);
      }
    }

    // Check if status changed to declined
    if (beforeData.status !== "declined" && afterData.status === "declined") {
      const techId = afterData.technicianId;
      try {
        const requestRef = db.collection("booking_request").doc(bookingId);
        const autoReqRef = db.collection("auto-assignment_requests").doc(bookingId);

        await Promise.allSettled([
          requestRef.update({
            rejectedTechnicians: FieldValue.arrayUnion(techId),
            updatedAt: FieldValue.serverTimestamp()
          }),
          autoReqRef.update({
            cancelledWorkerUids: FieldValue.arrayUnion(techId),
            updatedAt: FieldValue.serverTimestamp()
          })
        ]);
        console.log(`[Offer ${offerId}] Technician ${techId} declined and added to rejectedTechnicians list`);
      } catch (e) {
        console.error(`Error logging declination of offer ${offerId}:`, e);
      }
    }

    // Check if status changed to counter_offered
    if (beforeData.status !== "counter_offered" && afterData.status === "counter_offered") {
      try {
        const customerId = afterData.customerId;
        if (customerId) {
          const custSnap = await db.collection("customers").doc(customerId).get();
          if (custSnap.exists) {
            const custData = custSnap.data();
            if (custData.fcmToken && custData.fcmToken.trim() !== "") {
              let timeString = "a new time";
              if (afterData.proposedTime) {
                const date = afterData.proposedTime.toDate();
                timeString = `${date.getDate()}/${date.getMonth() + 1}/${date.getFullYear()} ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
              }

              const serviceName = afterData.serviceName || "your booking";
              const serviceNameAr = afterData.serviceNameAr || serviceName;
              const serviceNameUr = afterData.serviceNameUr || serviceNameAr;

              await sendAndStoreNotification({
                targetRole: "customer",
                targetId: customerId,
                titleEn: "Technician Proposed a New Time",
                titleAr: "اقترح الفني وقتاً جديداً",
                titleUr: "ٹیکنیشن نے نیا وقت تجویز کیا ہے",
                bodyEn: `The technician has proposed a new time: ${timeString} for ${serviceName}.`,
                bodyAr: `اقترح الفني وقتاً جديداً: ${timeString} لخدمة ${serviceNameAr}.`,
                bodyUr: `ٹیکنیشن نے ${serviceNameUr} کے لیے نیا وقت تجویز کیا ہے: ${timeString}۔`,
                data: {
                  bookingId: bookingId,
                  offerId: offerId,
                  category: "counter_offer",
                  type: "counter_offer"
                },
                fcmToken: custData.fcmToken,
                lanCode: custData.lanCode || "en"
              });
              console.log(`[Offer ${offerId}] Sent counter-proposal notification to customer ${customerId}`);
            }
          }
        }
      } catch (e) {
        console.error(`Error sending counter offer notification for offer ${offerId}:`, e);
      }
    }

    return null;
  }
);

// 3. Cron scheduled function for Auto-Assignment
exports.processAutoAssignments = onSchedule(
  "every 1 minutes",
  async (event) => {
    console.log("Processing scheduled auto-assignment requests...");
    const now = new Date();
    const threeHoursFromNow = new Date(now.getTime() + 3 * 60 * 60 * 1000);

    try {
      // Find pending auto-assignment requests safely
      const snapshot = await db.collection("auto-assignment_requests")
        .where("status", "==", "P")
        .get();

      console.log(`Found ${snapshot.size} pending auto-assignment requests to check`);

      for (const doc of snapshot.docs) {
        const request = doc.data();
        const requestId = doc.id;

        // Check if booking is still active/pending in bookings collection
        const bookingSnap = await db.collection("bookings").doc(requestId).get();
        if (!bookingSnap.exists) {
          console.log(`[Auto-Assignment ${requestId}] Booking document not found in bookings collection. Skipping.`);
          continue;
        }
        const bookingData = bookingSnap.data();
        if (bookingData.bookingStatusCode !== "P" && bookingData.bookingStatusCode !== "SR") {
          console.log(`[Auto-Assignment ${requestId}] Booking status is '${bookingData.bookingStatusCode}' (not 'P' or 'SR'). Syncing status and skipping.`);
          await db.collection("auto-assignment_requests").doc(requestId).update({
            status: bookingData.bookingStatusCode,
            updatedAt: FieldValue.serverTimestamp()
          });
          continue;
        }

        if (request.type === "instant") {
          // Always process instant bookings (broadcasting again to new techs)
        } else if (request.bookingDateTime) {
          const bookingDate = request.bookingDateTime.toDate();
          if (bookingDate > threeHoursFromNow) {
            continue; // Not within 3 hours yet
          }
        } else {
          continue;
        }

        const coords = extractCustomerCoordinates(request);
        if (!coords) continue;
        const custLat = coords.lat;
        const custLon = coords.lon;
        const customerAddress = extractCustomerAddress(request);

        // --- Send Customer Search Notification (For late bookings starting search for the first time) ---
        const shouldSendCustomerNotification = (request.type === "late" && request.notificationSent === false);

        if (shouldSendCustomerNotification) {
          const customerId = request.customer?.uid;
          if (customerId) {
            try {
              const customerDoc = await db.collection("customers").doc(customerId).get();
              if (customerDoc.exists) {
                const custData = customerDoc.data();
                const fcmToken = custData.fcmToken || request.customer?.fcmToken;
                const lan = custData.lanCode || request.customer?.lanCode || "en";
                if (fcmToken && fcmToken.trim() !== "") {
                  await sendAndStoreNotification({
                    targetRole: "customer",
                    targetId: customerId,
                    titleEn: "Searching for Technician",
                    titleAr: "جاري البحث عن فني",
                    titleUr: "ٹیکنیشن کی تلاش",
                    bodyEn: "We have started searching for eligible technicians for your booking.",
                    bodyAr: "لقد بدأنا في البحث عن الفنيين المؤهلين لحجزك.",
                    bodyUr: "ہم نے آپ کی بکنگ کے لیے اہل ٹیکنیشنز کی تلاش شروع کر دی ہے۔",
                    data: {
                      bookingId: requestId,
                      category: "searching_technician",
                      type: "searching_technician"
                    },
                    fcmToken: fcmToken,
                    lanCode: lan
                  });
                  console.log(`[Auto-Assignment ${requestId}] Customer notified that search has started`);
                }
              }
            } catch (err) {
              console.error(`Error notifying customer for search start:`, err);
            }
          }
        }

        // --- Get Existing Job Offers to Avoid Duplicate Notifications ---
        const existingOffersSnapshot = await db.collection("job_offers")
          .where("bookingId", "==", requestId)
          .get();

        const techsWithOffers = new Set();
        const nowTime = Date.now();
        existingOffersSnapshot.forEach(offerDoc => {
          const offer = offerDoc.data();
          if (offer.technicianId) {
            const expiresAt = offer.expiresAt ? offer.expiresAt.toDate().getTime() : 0;
            const isExpired = expiresAt < nowTime;

            if (offer.status === "pending" && !isExpired) {
              techsWithOffers.add(offer.technicianId);
            } else if (offer.status !== "pending") {
              techsWithOffers.add(offer.technicianId);
            }
          }
        });

        // --- Skip Cancelled Technicians ---
        const cancelledWorkerUids = request.cancelledWorkerUids || bookingData.cancelledWorkerUids || [];

        // Query eligible technicians
        const techsSnapshot = await db.collection("users")
          .where("role", "==", "technician")
          .where("isOnline", "==", true)
          .where("isVerified", "==", true)
          .get();

        const eligibleTechs = [];

        for (const techDoc of techsSnapshot.docs) {
          const tech = techDoc.data();
          const techUid = techDoc.id;

          // Skip if technician has already been offered this job
          if (techsWithOffers.has(techUid)) {
            continue;
          }

          // Skip if technician previously cancelled this booking
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

          // Started work check & Time Conflict check
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
              break;
            }
          }

          if (hasStartedJob) continue;

          eligibleTechs.push({ uid: techUid, data: tech });
        }

        if (eligibleTechs.length > 0 || shouldSendCustomerNotification) {
          const batch = db.batch();
          const expiresAtDate = new Date(Date.now() + 120 * 1000);
          const expiresAtTimestamp = admin.firestore.Timestamp.fromDate(expiresAtDate);

          for (const tech of eligibleTechs) {
            const offerId = db.collection("job_offers").doc().id;
            const offerRef = db.collection("job_offers").doc(offerId);

            batch.set(offerRef, {
              id: offerId,
              bookingId: requestId,
              technicianId: tech.uid,
              status: "pending",
              createdAt: FieldValue.serverTimestamp(),
              expiresAt: expiresAtTimestamp,
              customerName: request.customer?.name || "Customer",
              serviceLocation: {
                fullAddress: customerAddress?.fullName || customerAddress?.streetName || "Service Location",
                streetName: customerAddress?.streetName || "",
                lat: custLat,
                lon: custLon
              },
              serviceName: request.service?.name || "Service",
              serviceNameAr: request.service?.name_ar || request.service?.name || "Service",
              serviceNameUr: request.service?.name_ur || request.service?.name_ar || "Service",
              notes: request.notes || "",
              issueImage: request.issueImage || "",
              issueVideo: request.issueVideo || "",
              bookingDateTime: request.bookingDateTime,
              isRebook: false,
              customerId: request.customer?.uid || ""
            });

            // Push notifications
            if (tech.data.fcmToken && tech.data.fcmToken.trim() !== "") {
              const lan = tech.data.lanCode || "en";
              await sendAndStoreNotification({
                targetRole: "technician",
                targetId: tech.uid,
                titleEn: "New Auto-Assignment Job Available",
                titleAr: "وظيفة تعيين تلقائي جديدة متاحة",
                titleUr: "بکنگ کی نئی خودکار تفویض دستیاب ہے",
                bodyEn: "A new scheduled booking is available to accept.",
                bodyAr: "هناك حجز مجدول جديد متاح للقبول.",
                bodyUr: "قبول کرنے کے لیے ایک نئی طے شدہ بکنگ دستیاب ہے۔",
                data: {
                  bookingId: requestId,
                  offerId: offerId,
                  targetRole: "technician",
                  category: "job_offer",
                  type: "job_offer"
                },
                fcmToken: tech.data.fcmToken,
                lanCode: lan
              });
            }
          }

          if (shouldSendCustomerNotification) {
            batch.update(db.collection("auto-assignment_requests").doc(requestId), {
              notificationSent: true,
              updatedAt: FieldValue.serverTimestamp()
            });
          }

          await batch.commit();
          console.log(`[Auto-Assignment ${requestId}] Processed. Offers sent to ${eligibleTechs.length} technicians.`);
        } else {
          console.log(`No new technicians eligible for auto-assignment ${requestId} in this iteration.`);
        }
      }
    } catch (e) {
      console.error("Error processing late auto assignments: ", e);
    }
    return null;
  }
);

// 4. Trigger when auto-assignment request document is created
exports.onAutoAssignmentRequestCreated = onDocumentCreated(
  "auto-assignment_requests/{requestId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return null;

    const request = snap.data();
    const requestId = event.params.requestId;

    // We only process 'instant' here. 'late' is handled by the scheduled cron job.
    if (request.type !== "instant") {
      console.log(`[Auto-Assignment ${requestId}] Request type is 'late', skipping immediate notification.`);
      return null;
    }

    const coords = extractCustomerCoordinates(request);
    if (!coords) {
      console.error(`[Auto-Assignment ${requestId}] Invalid customer coordinates`);
      return null;
    }
    const custLat = coords.lat;
    const custLon = coords.lon;
    const customerAddress = extractCustomerAddress(request);

    try {
      const now = new Date();
      // --- Get Existing Job Offers to Avoid Duplicate Notifications ---
      const existingOffersSnapshot = await db.collection("job_offers")
        .where("bookingId", "==", requestId)
        .get();

      const techsWithOffers = new Set();
      const nowTime = Date.now();
      existingOffersSnapshot.forEach(offerDoc => {
        const offer = offerDoc.data();
        if (offer.technicianId) {
          const expiresAt = offer.expiresAt ? offer.expiresAt.toDate().getTime() : 0;
          const isExpired = expiresAt < nowTime;

          if (offer.status === "pending" && !isExpired) {
            techsWithOffers.add(offer.technicianId);
          } else if (offer.status !== "pending") {
            techsWithOffers.add(offer.technicianId);
          }
        }
      });

      // --- Skip Cancelled Technicians ---
      const cancelledWorkerUids = request.cancelledWorkerUids || [];

      // Find eligible technicians
      const techsSnapshot = await db.collection("users")
        .where("role", "==", "technician")
        .where("isOnline", "==", true)
        .where("isVerified", "==", true)
        .get();

      const eligibleTechs = [];

      for (const techDoc of techsSnapshot.docs) {
        const tech = techDoc.data();
        const techUid = techDoc.id;

        // Skip if technician has already been offered this job
        if (techsWithOffers.has(techUid)) {
          continue;
        }

        // Skip if technician previously cancelled this booking
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

        if (hasStartedJob || hasTimeConflict) continue;

        eligibleTechs.push({ uid: techUid, data: tech });
      }

      console.log(`[Auto-Assignment Instant ${requestId}] Found ${eligibleTechs.length} eligible technicians`);

      if (eligibleTechs.length === 0) {
        return null;
      }

      const batch = db.batch();
      const expiresAtDate = new Date(Date.now() + 120 * 1000);
      const expiresAtTimestamp = admin.firestore.Timestamp.fromDate(expiresAtDate);

      for (const tech of eligibleTechs) {
        const offerId = db.collection("job_offers").doc().id;
        const offerRef = db.collection("job_offers").doc(offerId);

        batch.set(offerRef, {
          id: offerId,
          bookingId: requestId,
          technicianId: tech.uid,
          status: "pending",
          createdAt: FieldValue.serverTimestamp(),
          expiresAt: expiresAtTimestamp,
          customerName: request.customer?.name || "Customer",
          serviceLocation: {
            fullAddress: customerAddress?.fullName || customerAddress?.streetName || "Service Location",
            streetName: customerAddress?.streetName || "",
            lat: custLat,
            lon: custLon
          },
          serviceName: request.service?.name || "Service",
          serviceNameAr: request.service?.name_ar || request.service?.name || "Service",
          serviceNameUr: request.service?.name_ur || request.service?.name_ar || "Service",
          notes: request.notes || "",
          issueImage: request.issueImage || "",
          issueVideo: request.issueVideo || "",
          bookingDateTime: request.bookingDateTime,
          isRebook: false,
          customerId: request.customer?.uid || ""
        });

        // Push notification
        if (tech.data.fcmToken && tech.data.fcmToken.trim() !== "") {
          const lan = tech.data.lanCode || "en";
          await sendAndStoreNotification({
            targetRole: "technician",
            targetId: tech.uid,
            titleEn: "New Auto-Assignment Job Available",
            titleAr: "وظيفة تعيين تلقائي جديدة متاحة",
            titleUr: "بکنگ کی نئی خودکار تفویض دستیاب ہے",
            bodyEn: "A new scheduled booking is available to accept.",
            bodyAr: "هناك حجز مجدول جديد متاح للقبول.",
            bodyUr: "قبول کرنے کے لیے ایک نئی طے شدہ بکنگ دستیاب ہے۔",
            data: {
              bookingId: requestId,
              offerId: offerId,
              targetRole: "technician",
              category: "job_offer",
              type: "job_offer"
            },
            fcmToken: tech.data.fcmToken,
            lanCode: lan
          });
        }
      }

      // Set notificationSent = true
      batch.update(db.collection("auto-assignment_requests").doc(requestId), {
        notificationSent: true,
        updatedAt: FieldValue.serverTimestamp()
      });

      await batch.commit();
      console.log(`[Auto-Assignment Instant ${requestId}] Offers and notifications sent to ${eligibleTechs.length} technicians`);

    } catch (e) {
      console.error(`Error processing instant auto-assignment ${requestId}:`, e);
    }
    return null;
  }
);

// 5. Trigger when a booking is assigned to copy the agent info to auto-assignment requests
exports.syncAgentToAutoAssignment = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const afterData = event.data.after.data();
    const beforeData = event.data.before.data();

    if (!afterData) return null;

    const bookingId = event.params.bookingId;

    // Check if agent was added
    if (afterData.agent && (!beforeData || !beforeData.agent)) {
      try {
        const autoReqRef = db.collection("auto-assignment_requests").doc(bookingId);
        const autoReqSnap = await autoReqRef.get();
        if (autoReqSnap.exists) {
          await autoReqRef.update({
            agent: afterData.agent,
            status: "assigned",
            updatedAt: FieldValue.serverTimestamp()
          });
          console.log(`[Sync Agent] Assigned agent ${afterData.agent.uid} synced to auto-assignment_requests ${bookingId}`);
        }
      } catch (e) {
        console.error(`Error syncing agent to auto-assignment request ${bookingId}:`, e);
      }
    }
    return null;
  }
);

// 6. Trigger when a booking is created to clean up all pending/stale job offers for that booking
exports.onBookingCreatedCleanupOffers = onDocumentCreated(
  "bookings/{bookingId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return null;
    const bookingId = event.params.bookingId;

    try {
      // Find all job offers matching this booking ID or request ID
      const snapshot = await db.collection("job_offers")
        .where("bookingId", "==", bookingId)
        .get();

      const batch = db.batch();
      snapshot.forEach((doc) => {
        batch.delete(doc.ref);
      });
      await batch.commit();
      console.log(`[Booking Created Cleanup] Deleted ${snapshot.size} job offers for booking ${bookingId}`);
    } catch (e) {
      console.error(`Error cleaning up job offers for booking ${bookingId}:`, e);
    }
    return null;
  }
);

// 7. Trigger when a booking request is deleted to clean up all corresponding job offers
exports.onBookingRequestDeletedCleanupOffers = onDocumentDeleted(
  "booking_request/{requestId}",
  async (event) => {
    const requestId = event.params.requestId;

    try {
      const snapshot = await db.collection("job_offers")
        .where("bookingId", "==", requestId)
        .get();

      const batch = db.batch();
      snapshot.forEach((doc) => {
        batch.delete(doc.ref);
      });
      await batch.commit();
      console.log(`[Booking Request Deleted Cleanup] Deleted ${snapshot.size} job offers for request ${requestId}`);
    } catch (e) {
      console.error(`Error cleaning up job offers for request ${requestId}:`, e);
    }
    return null;
  }
);

// 8. Trigger when technician registration is rejected or resubmitted
exports.notifyOnTechnicianRegistrationStatusChange = onDocumentUpdated(
  "users/{userId}",
  async (event) => {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();
    if (!afterData || !beforeData) return null;

    const userId = event.params.userId;

    if (afterData.role !== "technician") {
      return null;
    }

    // 1. Check if rejected
    const isNowUnverified = afterData.isVerified === false;
    const wasRejected = !beforeData.rejectionReason && afterData.rejectionReason;
    const rejectionReasonChanged = beforeData.rejectionReason !== afterData.rejectionReason;

    if (isNowUnverified && (wasRejected || rejectionReasonChanged) && afterData.rejectionReason) {
      if (afterData.fcmToken && afterData.fcmToken.trim() !== "") {
        try {
          await sendAndStoreNotification({
            targetRole: "technician",
            targetId: userId,
            titleEn: "Registration Rejected",
            titleAr: "تم رفض التسجيل",
            titleUr: "رجسٹریشن مسترد کر دی گئی",
            bodyEn: `Your registration was rejected. Reason: ${afterData.rejectionReason}`,
            bodyAr: `تم رفض تسجيلك. السبب: ${afterData.rejectionReason}`,
            bodyUr: `آپ کی رجسٹریشن مسترد کر دی گئی ہے۔ وجہ: ${afterData.rejectionReason}`,
            data: {
              targetRole: "technician",
              category: "registration_rejected",
              type: "registration_rejected"
            },
            fcmToken: afterData.fcmToken,
            lanCode: afterData.lanCode || "en"
          });
          console.log(`[${userId}] Rejection notification sent to technician.`);
        } catch (error) {
          console.error(`[${userId}] Error sending rejection notification to technician:`, error);
        }
      }
    }

    // 2. Check if resubmitted
    const wasPending = beforeData.isDocsPendingReview === true;
    const isNowPending = afterData.isDocsPendingReview === true;

    if (!wasPending && isNowPending) {
      const techName = afterData.name || "Technician";
      try {
        const adminUsersDocs = await getAllAdminUsers();

        const adminTokens = adminUsersDocs
          .filter(doc => doc.data().accessLevel !== 2) // Exclude customer service admins
          .map((doc) => {
            const data = doc.data();
            return data.fcmToken && data.fcmToken.trim() !== ""
              ? {
                uid: doc.id,
                token: data.fcmToken,
                lanCode: data.lanCode || "en",
              }
              : null;
          })
          .filter(Boolean);

        if (adminTokens.length > 0) {
          for (const { uid, token, lanCode } of adminTokens) {
            await sendAndStoreNotification({
              targetRole: "admin",
              targetId: uid,
              titleEn: "Technician Documents Resubmitted",
              titleAr: "إعادة إرسال مستندات الفني",
              titleUr: "ٹیکنیشن کی دستاویزات دوبارہ جمع کر دی گئیں",
              bodyEn: `Technician "${techName}" has resubmitted their documents for review.`,
              bodyAr: `أعاد الفني "${techName}" إرسال مستنداته للمراجعة.`,
              bodyUr: `ٹیکنیشن "${techName}" نے جائزے کے لیے اپنی دستاویزات دوبارہ جمع کر دی ہیں۔`,
              data: {
                targetRole: "admin",
                category: "technician_registration_resubmitted",
                technicianId: userId,
                technicianName: techName,
                isAdmin: "true",
                requestId: `${userId}_${Date.now()}`,
              },
              fcmToken: token,
              lanCode: lanCode,
            });
          }
          console.log(`[${userId}] Admin notifications sent for document resubmission.`);
        }
      } catch (error) {
        console.error(`[${userId}] Error sending admin notifications for document resubmission:`, error);
      }
    }

    // 3. Check if approved
    const wasVerified = beforeData.isVerified === true;
    const isNowVerified = afterData.isVerified === true;

    if (!wasVerified && isNowVerified) {
      if (afterData.fcmToken && afterData.fcmToken.trim() !== "") {
        try {
          await sendAndStoreNotification({
            targetRole: "technician",
            targetId: userId,
            titleEn: "Registration Approved",
            titleAr: "تمت الموافقة على التسجيل",
            titleUr: "رجسٹریشن منظور کر لی گئی",
            bodyEn: "Congratulations! Your registration has been approved. You can now start receiving requests.",
            bodyAr: "مبارك! تمت الموافقة على تسجيلك. يمكنك الآن البدء في تلقي الطلبات.",
            bodyUr: "مبارک ہو! آپ کی رجسٹریشن منظور کر لی گئی ہے۔ اب آپ درخواستیں وصول کرنا شروع کر سکتے ہیں۔",
            data: {
              targetRole: "technician",
              category: "registration_approved",
              type: "registration_approved"
            },
            fcmToken: afterData.fcmToken,
            lanCode: afterData.lanCode || "en"
          });
          console.log(`[${userId}] Approval notification sent to technician.`);
        } catch (error) {
          console.error(`[${userId}] Error sending approval notification to technician:`, error);
        }
      }
    }

    return null;
  }
);

// 9. Trigger when a rebooking job offer is created manually by the customer app
exports.onJobOfferCreatedForRebook = onDocumentCreated(
  "job_offers/{offerId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return null;
    const offerData = snap.data();

    // We only care about new rebooking job offers that are pending
    if (offerData.isRebook === true && offerData.status === "pending") {
      const technicianId = offerData.technicianId;
      if (!technicianId) return null;

      try {
        const techDoc = await admin.firestore().collection("users").doc(technicianId).get();
        if (!techDoc.exists) return null;

        const techData = techDoc.data();
        const serviceName = offerData.serviceName || "Service";
        const serviceNameAr = offerData.serviceNameAr || serviceName;
        const serviceNameUr = offerData.serviceNameUr || serviceNameAr;
        const customerName = offerData.customerName || "Customer";

        if (techData.fcmToken && techData.fcmToken.trim() !== "") {
          const lanCode = techData.lanCode || "en";
          await sendAndStoreNotification({
            targetRole: "technician",
            targetId: technicianId,
            titleEn: `New Booking Assigned: ${serviceName}`,
            titleAr: `تم تعيين حجز جديد: ${serviceNameAr}`,
            titleUr: `نیا بکنگ تفویض کیا گیا: ${serviceNameUr}`,
            bodyEn: "You have been assigned to a booking.",
            bodyAr: "لقد تم تعيينك في حجز جديد.",
            bodyUr: "آپ کو ایک بکنگ تفویض کی گئی ہے۔",
            data: {
              bookingId: offerData.requestId || offerData.bookingId || "",
              requestId: offerData.requestId || offerData.bookingId || "",
              offerId: event.params.offerId,
              targetRole: "technician",
              category: "booking",
              serviceName: serviceName,
              serviceNameAr: serviceNameAr,
              serviceNameUr: serviceNameUr,
              isAdmin: "false"
            },
            fcmToken: techData.fcmToken,
            lanCode: lanCode
          });
          console.log(`[${event.params.offerId}] Rebooking push notification sent to technician ${technicianId}.`);
        }

        // Also notify admins when customer completes a rebooking request
        const adminUsersDocs = await getAllAdminUsers();
        for (const doc of adminUsersDocs) {
          const user = doc.data();
          if (user.fcmToken && user.fcmToken.trim() !== "") {
            await sendAndStoreNotification({
              targetRole: "admin",
              targetId: doc.id,
              titleEn: `New Booking Request: ${serviceName}`,
              titleAr: `طلب حجز جديد: ${serviceNameAr}`,
              titleUr: `بکنگ کی نئی درخواست: ${serviceNameUr}`,
              bodyEn: `A new booking for ${serviceName} is pending approval.`,
              bodyAr: `هناك حجز جديد لـ ${serviceNameAr} بانتظار الموافقة.`,
              bodyUr: `${serviceNameUr} کے لیے ایک نئی بکنگ منظوری کا انتظار کر رہی ہے۔`,
              data: {
                bookingId: offerData.requestId || offerData.bookingId || "",
                requestId: offerData.requestId || offerData.bookingId || "",
                offerId: event.params.offerId,
                targetRole: "admin",
                category: "booking",
                serviceName: serviceName,
                serviceNameAr: serviceNameAr,
                serviceNameUr: serviceNameUr,
                isAdmin: "true"
              },
              fcmToken: user.fcmToken,
              lanCode: user.lanCode || "en"
            });
          }
        }
        console.log(`[${event.params.offerId}] Rebooking push notification sent to admins.`);
      } catch (error) {
        console.error(`[${event.params.offerId}] Error sending rebooking push notification:`, error);
      }
    }
    return null;
  }
);

// --- Assign newBookingId Logic ---
async function assignNewBookingIdHelper(docRef, data) {
  // If it already has a newBookingId, skip
  if (data.newBookingId) {
    return null;
  }

  const db = admin.firestore();

  // Check if there is a requestId or bookingId to carry over
  const sourceId = data.requestId || data.bookingId;
  if (sourceId) {
    const collectionsToCheck = ["booking_request", "job_requests", "auto-assignment_requests", "bookings"];
    for (const coll of collectionsToCheck) {
      try {
        const sourceDoc = await db.collection(coll).doc(sourceId).get();
        if (sourceDoc.exists) {
          const sourceData = sourceDoc.data();
          if (sourceData.newBookingId) {
            console.log(`Carrying over newBookingId ${sourceData.newBookingId} from ${coll}/${sourceId} to ${docRef.path}`);
            return docRef.update({ newBookingId: sourceData.newBookingId });
          }
        }
      } catch (err) {
        console.error(`Error checking source collection ${coll} for carry over:`, err);
      }
    }
  }

  // Generate new ID
  // To ensure the correct local time date or UTC date? The prompt says "first booking of 22nd june 2026 should be AG-260622-0001"
  // Let's use UTC or the server's local time. Server time is usually UTC.
  // Using a consistent timezone for date string generation. UTC is safest.
  const dateObj = new Date();
  const yy = String(dateObj.getUTCFullYear()).slice(-2);
  const mm = String(dateObj.getUTCMonth() + 1).padStart(2, '0');
  const dd = String(dateObj.getUTCDate()).padStart(2, '0');
  const dateString = `${yy}${mm}${dd}`;

  const counterRef = db.collection("counters").doc("daily_booking_id");

  try {
    const newId = await db.runTransaction(async (transaction) => {
      const counterDoc = await transaction.get(counterRef);
      let count = 1;

      if (counterDoc.exists) {
        const counterData = counterDoc.data();
        if (counterData.date === dateString) {
          count = (counterData.count || 0) + 1;
        }
      }

      transaction.set(counterRef, {
        date: dateString,
        count: count,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });

      const countString = String(count).padStart(4, '0');
      return `AG-${dateString}-${countString}`;
    });

    console.log(`Generated newBookingId ${newId} for ${docRef.path}`);
    return docRef.update({ newBookingId: newId });
  } catch (error) {
    console.error(`Error assigning newBookingId for ${docRef.path}:`, error);
    return null;
  }
}
exports.assignNewBookingIdHelper = assignNewBookingIdHelper;


// 9. Trigger when a new technician registers
exports.notifyOnNewTechnicianRegistration = onDocumentCreated(
  "users/{userId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return null;

    if (data.role !== "technician") return null;

    if (data.isDocsPendingReview === true) {
      const techName = data.name || "Technician";
      try {
        const adminUsersDocs = await getAllAdminUsers();

        const adminTokens = adminUsersDocs
          .filter(doc => doc.data().accessLevel !== 2) // Exclude customer service admins
          .map((doc) => {
            const adminData = doc.data();
            return adminData.fcmToken && adminData.fcmToken.trim() !== ""
              ? {
                uid: doc.id,
                token: adminData.fcmToken,
                lanCode: adminData.lanCode || "en",
              }
              : null;
          })
          .filter(Boolean);

        if (adminTokens.length > 0) {
          for (const { uid, token, lanCode } of adminTokens) {
            await sendAndStoreNotification({
              targetRole: "admin",
              targetId: uid,
              titleEn: "New Technician Registration",
              titleAr: "تسجيل فني جديد",
              titleUr: "نئے ٹیکنیشن کی رجسٹریشن",
              bodyEn: `Technician "${techName}" has registered and is pending review.`,
              bodyAr: `قام الفني "${techName}" بالتسجيل وبانتظار المراجعة.`,
              bodyUr: `ٹیکنیشن "${techName}" نے رجسٹریشن کرائی ہے اور جائزے کا منتظر ہے۔`,
              data: {
                targetRole: "admin",
                category: "new_technician_registration",
                technicianId: event.params.userId,
                technicianName: techName,
                isAdmin: "true",
              },
              fcmToken: token,
              lanCode: lanCode,
            });
          }
          console.log(`[${event.params.userId}] Admin notifications sent for new technician registration.`);
        }
      } catch (error) {
        console.error(`[${event.params.userId}] Error sending admin notifications for new technician registration:`, error);
      }
    }
    return null;
  }
);


exports.onBookingWarrantyUpdated = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const bookingId = event.params.bookingId;

    if (!before || !after) return null;

    const beforeStatus = before.warranty?.warrantyStatusCode;
    const afterStatus = after.warranty?.warrantyStatusCode;
    
    // Check if status changed
    if (beforeStatus !== afterStatus) {
      const customerId = after.customer?.uid;
      const techId = before.warranty?.assignedTechnicianId || after.warranty?.assignedTechnicianId;
      
      // Helper to fetch user data for FCM
      const fetchUserData = async (uid, role) => {
        const col = role === "customer" ? "customers" : "users";
        const doc = await db.collection(col).doc(uid).get();
        return doc.exists ? doc.data() : null;
      };

      // 1. Technician Acceptance (R -> S)
      if (beforeStatus === 'R' && afterStatus === 'S') {
        const techName = after.warranty?.assignedTechnician?.name || "The technician";
        
        // Notify Customer
        if (customerId) {
          const custData = await fetchUserData(customerId, "customer");
          await sendAndStoreNotification({
            targetRole: "customer",
            targetId: customerId,
            titleEn: "Warranty Request Accepted",
            titleAr: "تم قبول طلب الضمان",
            titleUr: "وارنٹی کی درخواست منظور کر لی گئی",
            bodyEn: `${techName} has accepted your warranty repair request.`,
            bodyAr: `لقد وافق ${techName} على طلب إصلاح الضمان الخاص بك.`,
            bodyUr: `${techName} نے آپ کی وارنٹی مرمت کی درخواست قبول کر لی ہے۔`,
            data: { type: "booking", requestId: bookingId },
            fcmToken: custData?.fcmToken,
            lanCode: custData?.lanCode,
          });
        }
        
        // Notify Admins
        const admins = await getAllAdminUsers();
        for (const adoc of admins) {
          const adminData = adoc.data();
          await sendAndStoreNotification({
            targetRole: "admin",
            targetId: adoc.id,
            titleEn: "Warranty Request Accepted",
            titleAr: "تم قبول طلب الضمان",
            titleUr: "وارنٹی کی درخواست منظور کر لی گئی",
            bodyEn: `${techName} has accepted warranty repair request ${bookingId}.`,
            bodyAr: `وافق ${techName} على طلب إصلاح الضمان ${bookingId}.`,
            bodyUr: `${techName} نے وارنٹی مرمت کی درخواست ${bookingId} قبول کر لی ہے۔`,
            data: { type: "booking", requestId: bookingId },
            fcmToken: adminData.fcmToken,
            lanCode: adminData.lanCode,
          });
        }
      }

      // 2. Admin Rejection (changed to X)
      if (afterStatus === 'X' && beforeStatus === 'R') {
        if (customerId) {
          const custData = await fetchUserData(customerId, "customer");
          await sendAndStoreNotification({
            targetRole: "customer",
            targetId: customerId,
            titleEn: "Warranty Request Rejected",
            titleAr: "تم رفض طلب الضمان",
            titleUr: "وارنٹی کی درخواست مسترد کر دی گئی",
            bodyEn: `Your warranty repair request has been rejected by the administration.`,
            bodyAr: `تم رفض طلب إصلاح الضمان الخاص بك من قبل الإدارة.`,
            bodyUr: `آپ کی وارنٹی مرمت کی درخواست انتظامیہ نے مسترد کر دی ہے۔`,
            data: { type: "booking", requestId: bookingId },
            fcmToken: custData?.fcmToken,
            lanCode: custData?.lanCode,
          });
        }
      }
    }
    
    // Technician Rejection/Cancellation or Reassignment
    const beforeTechId = before.warranty?.assignedTechnicianId;
    const afterTechId = after.warranty?.assignedTechnicianId;
    
    const fetchUserData = async (uid, role) => {
      const col = role === "customer" ? "customers" : "users";
      const doc = await db.collection(col).doc(uid).get();
      return doc.exists ? doc.data() : null;
    };

    // 3. Technician Rejection / Cancellation (removed assigned technician)
    if (beforeTechId && !afterTechId) {
      const customerId = after.customer?.uid;
      // Notify Customer
      if (customerId) {
        const custData = await fetchUserData(customerId, "customer");
        await sendAndStoreNotification({
          targetRole: "customer",
          targetId: customerId,
          titleEn: "Technician Unavailable",
          titleAr: "الفني غير متاح",
          titleUr: "ٹیکنیشن دستیاب نہیں",
          bodyEn: `The technician cancelled your warranty repair request. A new technician will be assigned shortly. You may submit a complaint if delayed.`,
          bodyAr: `قام الفني بإلغاء طلب إصلاح الضمان الخاص بك. سيتم تعيين فني جديد قريباً. يمكنك تقديم شكوى في حال التأخير.`,
          bodyUr: `ٹیکنیشن نے آپ کی وارنٹی مرمت کی درخواست منسوخ کر دی ہے۔ جلد ہی نیا ٹیکنیشن تفویض کیا جائے گا۔ تاخیر کی صورت میں آپ شکایت درج کر سکتے ہیں۔`,
          data: { type: "booking", requestId: bookingId },
          fcmToken: custData?.fcmToken,
          lanCode: custData?.lanCode,
        });
      }
      
      // Notify Admins
      const admins = await getAllAdminUsers();
      for (const adoc of admins) {
        const adminData = adoc.data();
        await sendAndStoreNotification({
          targetRole: "admin",
          targetId: adoc.id,
          titleEn: "Warranty Technician Rejected / Cancelled",
          titleAr: "الفني رفض / ألغى الضمان",
          titleUr: "وارنٹی ٹیکنیشن نے مسترد / منسوخ کر دیا",
          bodyEn: `The technician cancelled the warranty repair request ${bookingId}. Check and review the booking.`,
          bodyAr: `قام الفني بإلغاء طلب إصلاح الضمان ${bookingId}. يرجى التحقق ومراجعة الحجز.`,
          bodyUr: `ٹیکنیشن نے وارنٹی مرمت کی درخواست ${bookingId} منسوخ کر دی۔ براہ کرم بکنگ چیک کریں اور جائزہ لیں۔`,
          data: { type: "booking", requestId: bookingId },
          fcmToken: adminData.fcmToken,
          lanCode: adminData.lanCode,
        });
      }
    }
    
    // 4. Technician Assign/Reassign (changed from one tech to another, or from null to tech)
    if (afterTechId && beforeTechId !== afterTechId) {
      const customerId = after.customer?.uid;
      const techName = after.warranty?.assignedTechnician?.name || "A new technician";
      
      // Notify Customer
      if (customerId) {
        const custData = await fetchUserData(customerId, "customer");
        await sendAndStoreNotification({
          targetRole: "customer",
          targetId: customerId,
          titleEn: "Technician Assigned",
          titleAr: "تم تعيين فني",
          titleUr: "ٹیکنیشن تفویض کر دیا گیا",
          bodyEn: `${techName} has been assigned to your warranty repair request.`,
          bodyAr: `تم تعيين ${techName} لطلب إصلاح الضمان الخاص بك.`,
          bodyUr: `${techName} کو آپ کی وارنٹی مرمت کی درخواست کے لیے تفویض کیا گیا ہے۔`,
          data: { type: "booking", requestId: bookingId },
          fcmToken: custData?.fcmToken,
          lanCode: custData?.lanCode,
        });
      }
      
      // Notify New Technician
      const techData = await fetchUserData(afterTechId, "technician");
      await sendAndStoreNotification({
        targetRole: "technician",
        targetId: afterTechId,
        titleEn: "Warranty Repair Assigned",
        titleAr: "تم تعيين إصلاح الضمان",
        titleUr: "وارنٹی مرمت تفویض کر دی گئی",
        bodyEn: `You have been assigned a new warranty repair request.`,
        bodyAr: `تم تعيينك لطلب إصلاح ضمان جديد.`,
        bodyUr: `آپ کو ایک نئی وارنٹی مرمت کی درخواست تفویض کی گئی ہے۔`,
        data: { type: "booking", requestId: bookingId },
        fcmToken: techData?.fcmToken,
        lanCode: techData?.lanCode,
      });
    }

    return null;
  }
);
