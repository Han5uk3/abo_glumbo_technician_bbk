const {
  onDocumentCreated,
  onDocumentWritten,
} = require("firebase-functions/v2/firestore");
const { onRequest } = require("firebase-functions/v2/https");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onValueCreated } = require("firebase-functions/v2/database");
const { logger } = require("firebase-functions/v2");
const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

// Helper function to send FCM and store notification in Firestore
async function sendAndStoreNotification({
  targetRole, // 'customer', 'technician', 'admin'
  targetId,
  titleEn,
  titleAr,
  bodyEn,
  bodyAr,
  data,
  fcmToken,
  lanCode,
}) {
  // 1. Determine collection based on role
  // Customer -> customers collection
  // Technician/Admin -> users collection
  let collectionName = "users";
  if (targetRole === "customer") {
    collectionName = "customers";
  }

  // Check for duplicate notification
  const query = admin.firestore().collection(collectionName).doc(targetId).collection("notifications").where("titleEn", "==", titleEn).where("bodyEn", "==", bodyEn);
  try {
    const existing = await query.get();
    if (!existing.empty) {
      console.log(`Duplicate notification detected for ${targetRole} ${targetId}, skipping`);
      return null;
    }
  } catch (error) {
    console.error(`Error checking for duplicate notification:`, error);
    // Continue anyway
  }

  // 2. Store in Firestore (subcollection 'notifications')
  try {
    await admin
      .firestore()
      .collection(collectionName)
      .doc(targetId)
      .collection("notifications")
      .add({
        titleEn,
        titleAr,
        bodyEn,
        bodyAr,
        data: data || {},
        read: false,
        createdAt: FieldValue.serverTimestamp(),
      });
    console.log(`Notification stored for ${targetRole} ${targetId}`);
  } catch (e) {
    console.error(
      `Error storing notification for ${targetRole} ${targetId}:`,
      e
    );
  }

  // 3. Send FCM
  if (fcmToken && fcmToken.trim() !== "") {
    const title = lanCode === "ar" ? titleAr : titleEn;
    const body = lanCode === "ar" ? bodyAr : bodyEn;

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

// Helper function to get all admin users (main admins + granted admins)
// Excludes customer service admins (adminAccessLevel == 2)
async function getAllAdminUsers() {
  try {
    // Fetch main admins (isAdmin == true)
    const adminUsersDocs = await getAllAdminUsers();

    // Fetch technicians granted admin access (isGrantedAdminByMain == true)
    const grantedAdminsSnapshot = await admin
      .firestore()
      .collection("users")
      .where("isGrantedAdminByMain", "==", true)
      .get();

    // Combine both groups and filter out customer service admins
    const adminUsersMap = new Map();

    mainAdminsSnapshot.forEach((doc) => {
      const data = doc.data();
      // Include if adminAccessLevel is 1 or undefined (main admin)
      // Exclude if adminAccessLevel is 2 (customer service)
      if (!data.adminAccessLevel || data.adminAccessLevel === 1) {
        adminUsersMap.set(doc.id, doc);
      }
    });

    grantedAdminsSnapshot.forEach((doc) => {
      const data = doc.data();
      // Only include full admins (level 1), exclude customer service (level 2)
      if (data.adminAccessLevel === 1 && !adminUsersMap.has(doc.id)) {
        adminUsersMap.set(doc.id, doc);
      }
    });

    return Array.from(adminUsersMap.values());
  } catch (error) {
    console.error("Error fetching admin users:", error);
    return [];
  }
}

exports.notifyAdminsOnNewBooking = onDocumentCreated(
  "bookings/{bookingId}",
  async (event) => {
    const snap = event.data;
    if (!snap) {
      console.log("No data associated with the event");
      return;
    }

    const booking = snap.data();
    if (booking.bookingStatusCode !== "P") {
      console.log("Booking is not pending, skipping notification.");
      return null;
    }

    const serviceName = booking.service?.name || "Service";
    const serviceNameAr = booking.service?.name_ar || serviceName;

    try {
      const adminUsersDocs = await getAllAdminUsers();

      const tokensWithLanguage = [];
      adminUsersDocs.forEach((doc) => {
        const user = doc.data();
        if (user.fcmToken && user.fcmToken.trim() !== "") {
          tokensWithLanguage.push({
            uid: doc.id,
            token: user.fcmToken,
            lanCode: user.lanCode,
          });
        }
      });

      if (tokensWithLanguage.length === 0) {
        console.log("No admin tokens found.");
        return null;
      }

      const results = [];

      for (const { uid, token, lanCode } of tokensWithLanguage) {
        await sendAndStoreNotification({
          targetRole: "admin",
          targetId: uid,
          titleEn: `New Booking Request: ${serviceName}`,
          titleAr: `طلب حجز جديد: ${serviceNameAr}`,
          bodyEn: `A new booking for ${serviceName} is pending approval.`,
          bodyAr: `هناك حجز جديد لـ ${serviceNameAr} بانتظار الموافقة.`,
          data: {
            targetRole: "admin",
            category: "booking",
            bookingId: event.params.bookingId,
            serviceName: serviceName,
            serviceNameAr: serviceNameAr,
            isAdmin: "true",
          },
          fcmToken: token,
          lanCode: lanCode,
        });
      }
    } catch (error) {
      console.error("Error sending admin notifications:", error);
    }

    return null;
  }
);
exports.notifyAgentOnAssignment = onDocumentWritten(
  "bookings/{bookingId}",
  async (event) => {
    const bookingId = event.params.bookingId;
    const beforeData = event.data?.before?.data() || {};
    const afterData = event.data?.after?.data() || {};

    if (!afterData) {
      console.log(`[${bookingId}] Document deleted, skipping...`);
      return;
    }

    const serviceName = afterData?.service?.name || "Service";
    const serviceNameAr = afterData?.service?.name_ar || serviceName;

    // --- Fetch admin users once ---
    let adminTokens = [];
    try {
      const adminUsersDocs = await getAllAdminUsers();

      adminTokens = adminUsersDocs
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

      if (adminTokens.length === 0) {
        console.log(`[${bookingId}] No admin FCM tokens found`);
      }
    } catch (error) {
      console.error(`[${bookingId}] Error fetching admin users:`, error);
    }

    // ==============================
    // 1. New Assignment Notification
    // ==============================
    const statusChangedToAssigned =
      beforeData?.bookingStatusCode !== "A" &&
      afterData.bookingStatusCode === "A";

    if (statusChangedToAssigned) {
      const agent = afterData.agent;
      if (!agent?.uid) {
        console.log(
          `[${bookingId}] No agent assigned, skipping assignment notification`
        );
      } else {
        try {
          const agentDoc = await admin
            .firestore()
            .collection("users")
            .doc(agent.uid)
            .get();

          if (!agentDoc.exists) {
            console.log(`[${bookingId}] Agent user not found`);
          } else {
            const agentData = agentDoc.data();
            const agentLanCode = agentData.lanCode || "en";
            const agentFcmToken = agentData.fcmToken;

            await sendAndStoreNotification({
              targetRole: "technician",
              targetId: agent.uid,
              titleEn: `New Booking Assigned: ${serviceName}`,
              titleAr: `تم تعيين حجز جديد: ${serviceNameAr}`,
              bodyEn: `You have accepted a new booking for "${serviceName}"`,
              bodyAr: `لقد قبلت حجزاً جديداً لخدمة "${serviceNameAr}"`,
              data: {
                targetRole: "technician",
                category: "booking",
                bookingId,
                serviceName,
                serviceNameAr: serviceNameAr,
                isAdmin: "false",
              },
              fcmToken: agentFcmToken,
              lanCode: agentLanCode,
            });
          }
        } catch (error) {
          console.error(
            `[${bookingId}] Error sending worker assignment notification:`,
            error
          );
        }
      }

      // Notify admins about assignment
      if (adminTokens.length > 0) {
        for (const { uid, token, lanCode } of adminTokens) {
          await sendAndStoreNotification({
            targetRole: "admin",
            targetId: uid,
            titleEn: `New Agent Assigned: ${serviceName}`,
            titleAr: `تم تعيين فني جديد: ${serviceNameAr}`,
            bodyEn: `A technician has been assigned to a new booking for "${serviceName}".`,
            bodyAr: `تم تعيين فني لحجز جديد لخدمة "${serviceNameAr}".`,
            data: {
              targetRole: "admin",
              category: "booking",
              bookingId,
              serviceName,
              serviceNameAr: serviceNameAr,
              isAdmin: "true",
            },
            fcmToken: token,
            lanCode: lanCode,
          });
        }
      }
    }

    // ==============================
    // 2. Worker Cancellation Notification
    // ==============================
    try {
      const beforeCancelledWorkers = beforeData.cancelledWorkers || [];
      const afterCancelledWorkers = afterData.cancelledWorkers || [];

      // Find new worker(s) who cancelled
      const newCancellations = afterCancelledWorkers.filter(
        (worker) =>
          !beforeCancelledWorkers.some(
            (w) =>
              w.uid === worker.uid &&
              w.cancelledAt?.toMillis?.() === worker.cancelledAt?.toMillis?.()
          )
      );

      if (newCancellations.length > 0) {
        const latestCancelled = newCancellations[newCancellations.length - 1];
        const workerName = latestCancelled?.agentName || "Unknown Worker";
        const workerId = latestCancelled?.uid || "";

        if (adminTokens.length > 0) {
          for (const { uid, token, lanCode } of adminTokens) {
            await sendAndStoreNotification({
              targetRole: "admin",
              targetId: uid,
              titleEn: "Booking Cancelled by Technician",
              titleAr: "إلغاء الحجز من قبل الفني",
              bodyEn: `The booking has been cancelled by Technician ${workerName}.`,
              bodyAr: `تم إلغاء الحجز من قبل الفني ${workerName}.`,
              data: {
                targetRole: "admin",
                category: "booking",
                bookingId,
                workerId,
                workerName,
                isAdmin: "true",
              },
              fcmToken: token,
              lanCode: lanCode,
            });
          }
        }
      }
    } catch (error) {
      console.error(
        `[${bookingId}] Error notifying admins of cancellation:`,
        error
      );
    }

    return null;
  }
);
exports.notifyCustomerOnBookingStatusChange = onDocumentWritten(
  "bookings/{bookingId}",
  async (event) => {
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();

    if (!afterData) {
      console.log("Document deleted, skipping...");
      return;
    }

    if (afterData.bookingStatusCode === "P") {
      console.log("Booking status is pending, skipping notification...");
      return;
    }

    // Check for status change or payment completion change
    const statusChanged =
      beforeData?.bookingStatusCode !== afterData.bookingStatusCode;
    const paymentCompleted =
      beforeData?.paymentCompleted !== afterData.paymentCompleted;

    if (!statusChanged && !paymentCompleted) {
      console.log("No relevant changes detected, skipping...");
      return;
    }

    // Only send payment completed notification if status is already "C"
    if (paymentCompleted && afterData.bookingStatusCode !== "C") {
      console.log(
        "Payment completed notification only sent for completed bookings (C)..."
      );
      return;
    }

    const customer = afterData.customer;
    const customerId = customer?.uid;
    if (!customer) {
      console.log("No customer found.");
      return;
    }

    let customerData;
    try {
      const customerDoc = await admin
        .firestore()
        .collection("customers")
        .doc(customerId)
        .get();
      if (!customerDoc.exists) {
        console.log("Customer document not found.");
        return;
      }
      customerData = customerDoc.data();
    } catch (error) {
      console.error("Error fetching customer data:", error);
      return;
    }

    const fcmToken = customerData?.fcmToken;
    const lanCode = customerData?.lanCode || "en";

    if (!fcmToken || fcmToken.trim() === "") {
      console.log("Customer has no valid FCM token.");
      return;
    }

    const service = afterData.service;
    const serviceName = service?.name || "Service";
    const serviceNameAr = service?.name_ar || serviceName;
    const bookingStatus = afterData.bookingStatusCode;
    const isPaymentCompleted = afterData.paymentCompleted;

    const statusMessages = {
      A: {
        en: "Your booking has been accepted.",
        ar: "تم قبول حجزك.",
      },
      R: {
        en: "Your booking has been rejected.",
        ar: "تم رفض حجزك.",
      },
      C: {
        // Service complete
        en: "Your service is complete!\nWe hope you had a great experience.",
        ar: "تم الانتهاء من خدمتك!\nنأمل أن تكون قد قضيت وقتًا رائعًا.",
      },
      C_PAYMENT_COMPLETED: {
        // Service complete and payment received
        en: "Thank you! Your payment has been received.\nWe'd love to hear about your experience.\nPlease share your feedback by rating your service provider.\nYour reviews help us maintain the best service quality.\nIf you'd like, you can also leave a tip to show your appreciation.",
        ar: "شكراً لك! تم استلام دفعتك.\nنود أن نسمع عن تجربتك.\nيرجى مشاركة آرائك بتقييم مقدم الخدمة الخاص بك.\nتساعدنا تقييماتك في الحفاظ على أفضل جودة للخدمة.\nوإذا رغبت، يمكنك ترك إكرامية.",
      },
      XC: {
        en: "Your booking has been canceled.",
        ar: "تم إلغاء حجزك.",
      },
    };

    // Determine which message to use
    let messageKey = bookingStatus;
    if (bookingStatus === "C" && isPaymentCompleted && afterData.completionData?.mode !== 0) {
      messageKey = "C_PAYMENT_COMPLETED";
    }

    const bodyEn =
      statusMessages[messageKey]?.["en"] ||
      `Your booking status changed to ${bookingStatus}`;
    const bodyAr =
      statusMessages[messageKey]?.["ar"] ||
      `تغيرت حالة حجزك إلى ${bookingStatus}`;

    await sendAndStoreNotification({
      targetRole: "customer",
      targetId: customerId,
      titleEn: "Booking Status Update",
      titleAr: "تحديث حالة الحجز",
      bodyEn: `${bodyEn} (${serviceName})`,
      bodyAr: `${bodyAr} (${serviceNameAr})`,
      data: {
        customerId: customerId,
        targetRole: "customer",
        bookingId: event.params.bookingId,
        status: bookingStatus,
        serviceName: serviceName,
        serviceNameAr: serviceNameAr,
        paymentCompleted: isPaymentCompleted.toString(),
      },
      fcmToken: fcmToken,
      lanCode: lanCode,
    });
  }
);
exports.notifyTechnicianOnPaymentCompletion = onDocumentWritten(
  "bookings/{bookingId}",
  async (event) => {
    const bookingId = event.params.bookingId;
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();

    if (!afterData) {
      console.log(`[${bookingId}] Document deleted, skipping...`);
      return;
    }

    // Check if payment was just completed
    const wasPaymentCompleted = beforeData?.paymentCompleted || false;
    const isPaymentCompleted = afterData.paymentCompleted || false;

    if (!isPaymentCompleted || wasPaymentCompleted) {
      // Payment not completed or already was completed before
      return;
    }

    // Omit payment received notification for inspection only bookings
    if (afterData.completionData?.mode === 0) {
      console.log(`[${bookingId}] Inspection only booking, skipping payment received notification.`);
      return;
    }

    // Only notify if booking is completed
    if (afterData.bookingStatusCode !== "C") {
      console.log(
        `[${bookingId}] Payment completed but booking status is not 'C', skipping...`
      );
      return;
    }

    // Skip payment notification only for warranty REPAIRS (not initial warranty)
    // Flow: Warranty is added when technician completes work (bookingStatusCode = "C") with status "A"
    // When customer completes payment, warranty still has status "A" - allow payment notification
    // When warranty repair is requested/in-progress (R, S, C), skip payment notification
    if (afterData.warranty) {
      const warrantyStatus = afterData.warranty.warrantyStatusCode;
      if (warrantyStatus !== "A") {
        console.log(
          `[${bookingId}] ⚠️ SKIPPING payment notification - this is a warranty repair. Warranty status: ${warrantyStatus}`
        );
        return;
      }
      console.log(
        `[${bookingId}] ℹ️ Warranty exists with status A (available) - proceeding with payment notification`
      );
    }

    console.log(`[${bookingId}] ✅ Proceeding with payment notification`);

    const agent = afterData.agent;
    if (!agent?.uid) {
      console.log(`[${bookingId}] No agent assigned, skipping notification`);
      return;
    }

    // Fetch technician data
    let technicianData;
    try {
      const technicianDoc = await admin
        .firestore()
        .collection("users")
        .doc(agent.uid)
        .get();

      if (!technicianDoc.exists) {
        console.log(`[${bookingId}] Technician document not found`);
        return;
      }

      technicianData = technicianDoc.data();
    } catch (error) {
      console.error(`[${bookingId}] Error fetching technician data:`, error);
      return;
    }

    const fcmToken = technicianData?.fcmToken;
    const lanCode = technicianData?.lanCode || "en";

    if (!fcmToken || fcmToken.trim() === "") {
      console.log(`[${bookingId}] Technician has no valid FCM token`);
      return;
    }

    const serviceName = afterData.service?.name || "Service";
    const serviceNameAr = afterData.service?.name_ar || serviceName;
    const customerName = afterData.customer?.name || "Customer";

    // Get payment amount from completionData
    const inspectionOnly = afterData.completionData?.mode === 0 || false;
    const totalAmount = inspectionOnly
      ? afterData.completionData?.inspectionFee || 0
      : afterData.completionData?.totalCost || 0;

    await sendAndStoreNotification({
      targetRole: "technician",
      targetId: agent.uid,
      titleEn: "Payment Received",
      titleAr: "تم استلام الدفع",
      bodyEn: `${customerName} has completed payment of ${totalAmount} for ${serviceName}. The transaction is now complete.`,
      bodyAr: `قام ${customerName} بإكمال دفع ${totalAmount} مقابل ${serviceNameAr}. اكتملت المعاملة الآن.`,
      data: {
        targetRole: "technician",
        category: "payment",
        bookingId,
        serviceName,
        serviceNameAr: serviceNameAr,
        customerName,
        amount: totalAmount.toString(),
        isAdmin: "false",
      },
      fcmToken: fcmToken,
      lanCode: lanCode,
    });

    console.log(
      `[${bookingId}] Payment completion notification sent to technician ${agent.uid}`
    );
  }
);

exports.customerTrackingNotification = onDocumentWritten(
  "bookings/{bookingId}",
  async (event) => {
    const afterData = event.data?.after?.data();
    const beforeData = event.data?.before?.data();

    if (!afterData) {
      console.log("Document deleted, skipping...");
      return;
    }

    const customer = afterData.customer;
    const customerId = customer?.uid;

    if (!customerId) {
      console.log("No customer UID found.");
      return;
    }

    let customerData;
    try {
      const customerDoc = await admin
        .firestore()
        .collection("customers")
        .doc(customerId)
        .get();

      if (!customerDoc.exists) {
        console.log("Customer document not found.");
        return;
      }

      customerData = customerDoc.data();
    } catch (error) {
      console.error("Error fetching customer data:", error);
      return;
    }

    const fcmToken = customerData?.fcmToken;
    const lanCode = customerData?.lanCode || "en";

    if (!fcmToken || fcmToken.trim() === "") {
      console.log("Customer has no valid FCM token.");
      return;
    }

    const isAccepted = afterData.bookingStatusCode === "A";
    if (!isAccepted) {
      console.log("Booking not accepted, skipping tracking notification...");
      return;
    }

    const wasStarted = beforeData?.isStarted;
    const isStartedNow = afterData.isStarted;
    if (wasStarted === isStartedNow) return;

    // Determine titles and bodies for both languages
    let titleEn, titleAr, bodyEn, bodyAr;

    if (!wasStarted && isStartedNow) {
      titleEn = "Tracking Started";
      titleAr = "بدء تتبع الحجز";
      bodyEn =
        "The Technician has started tracking your location for the booking.";
      bodyAr = "يمكنك الآن تتبع حالة حجزك.";
    } else if (wasStarted && !isStartedNow) {
      titleEn = "Tracking Stopped";
      titleAr = "إيقاف تتبع الحجز";
      bodyEn = "Tracking has been stopped by the Technician.";
      bodyAr = "تم إيقاف تتبع موقعك بواسطة الفني.";
    }

    await sendAndStoreNotification({
      targetRole: "customer",
      targetId: customerId,
      titleEn,
      titleAr,
      bodyEn,
      bodyAr,
      data: {},
      fcmToken: fcmToken,
      lanCode: lanCode,
    });
  }
);
exports.onBookingUpdateToTip = onDocumentWritten(
  "bookings/{bookingId}",
  async (event) => {
    const bookingId = event.params.bookingId;
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();

    console.log(`Triggered for bookingId: ${bookingId}`);

    if (!after) {
      console.log("Document deleted, skipping.");
      return;
    }

    const wasTipPaid = before?.review?.isTipPaid || false;
    const isTipPaid = after?.review?.isTipPaid || false;
    const tipAmount = after?.review?.tipAmount || 0;
    const paymentType = after?.review?.paymentType || "cash"; // Get payment type

    if (isTipPaid && !wasTipPaid && tipAmount > 0) {
      console.log("New tip detected. Processing...");
    } else {
      console.log("No new tip paid or already processed. Skipping.");
      return;
    }

    const agent = after.agent;

    if (!agent?.uid) {
      console.error("Missing agent UID in booking data.");
      return;
    }
    const tippingWalletId = agent.uid;
    const tippingRef = db.collection("tipping").doc(tippingWalletId);

    try {
      await db.runTransaction(async (tx) => {
        const tippingDoc = await tx.get(tippingRef);

        // Get existing tip amounts based on new model structure
        const existingCashTip = tippingDoc.exists
          ? tippingDoc.data().cashtip || 0
          : 0;
        const existingCardTip = tippingDoc.exists
          ? tippingDoc.data().cardtip || 0
          : 0;

        // Determine which tip field to update based on payment type
        const isCardPayment =
          paymentType.toLowerCase() === "cards" ||
          paymentType.toLowerCase() === "card";

        const updateData = {
          walletId: tippingWalletId,
          agentId: agent.uid,
          agentName: agent.name || "",
          agentPhone: agent.phone || "",
          lastUpdated: FieldValue.serverTimestamp(),
          cashtip: isCardPayment
            ? existingCashTip
            : existingCashTip + tipAmount,
          cardtip: isCardPayment
            ? existingCardTip + tipAmount
            : existingCardTip,
          payoutRequested: false, // Add new field from model
        };

        if (!tippingDoc.exists) {
          console.log("Creating new tipping document.");
          tx.set(tippingRef, updateData);
        } else {
          console.log(
            `Updating tipping document. Current cash: ${existingCashTip}, card: ${existingCardTip}`
          );
          tx.update(tippingRef, updateData);
        }

        const agentFcmToken = agent.fcmToken;

        const tipType = isCardPayment ? "card" : "cash";

        await sendAndStoreNotification({
          targetRole: "technician",
          targetId: agent.uid,
          titleEn: "New Tip Received",
          titleAr: "تم استلام إكرامية جديدة",
          bodyEn: `Customer gave you a tip of ${tipAmount} SAR.`,
          bodyAr: `العميل قدّم لك إكرامية بقيمة ${tipAmount} ر.س.`,
          data: {
            category: "tip",
            amount: tipAmount.toString(),
            type: tipType,
            isAdmin: "false",
          },
          fcmToken: agentFcmToken,
          lanCode: agent.lanCode || "en",
        });
      });

      console.log(
        `Successfully updated ${isCardPayment ? "card" : "cash"
        } tip +${tipAmount} for agent ${agent.name} (${agent.uid})`
      );
    } catch (error) {
      console.error("Error processing tip update:", error);
    }
  }
);

exports.updateServiceRating = onDocumentWritten(
  "bookings/{bookingId}",
  async (event) => {
    const change = event.data;
    const afterData = change.after.exists ? change.after.data() : null;
    const beforeData = change.before.exists ? change.before.data() : null;

    const newRating = afterData?.review?.rating;
    const oldRating = beforeData?.review?.rating;

    if (typeof newRating !== "number") {
      console.log("No valid new rating found.");
      return null;
    }

    const serviceId = afterData?.service?.id;
    if (!serviceId) {
      console.log("No valid service ID found.");
      return null;
    }

    const serviceRef = admin.firestore().collection("services").doc(serviceId);

    await admin.firestore().runTransaction(async (transaction) => {
      const serviceDoc = await transaction.get(serviceRef);

      if (!serviceDoc.exists) {
        throw new Error("Service document does not exist.");
      }

      const data = serviceDoc.data();
      const currentTotal = data.totalRating || 0;
      const currentCount = data.ratingCount || 0;

      let updatedTotal = currentTotal;
      let updatedCount = currentCount;

      if (typeof oldRating !== "number") {
        updatedTotal += newRating;
        updatedCount += 1;
      } else if (oldRating !== newRating) {
        updatedTotal = updatedTotal - oldRating + newRating;
      }

      transaction.update(serviceRef, {
        totalRating: updatedTotal,
        ratingCount: updatedCount,
      });
    });

    console.log(`Processed rating: ${newRating} for service: ${serviceId}`);
    return null;
  }
);
exports.sendNotificationToFCM = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).send("Only POST method is allowed");
  }

  const { fcmToken, title, body } = req.body;

  if (!fcmToken || !title || !body) {
    return res.status(400).send("Missing fcmToken, title, or body");
  }

  if (typeof fcmToken !== "string" || fcmToken.trim() === "") {
    return res.status(400).send("Invalid FCM token format");
  }

  console.log(`Sending notification to token: ${fcmToken.substring(0, 20)}...`);

  const message = {
    notification: {
      title,
      body,
    },
    token: fcmToken.trim(),
  };

  try {
    const response = await admin.messaging().send(message);
    console.log("Notification sent to token:", fcmToken);
    return res.status(200).send({
      success: true,
      messageId: response,
    });
  } catch (error) {
    console.error("Error sending notification:", error);
    return res.status(500).send({
      success: false,
      error: error.message,
    });
  }
});

exports.notifyWorkerOnNewBooking = onDocumentCreated(
  "bookings/{bookingId}",
  async (event) => {
    const snap = event.data;
    if (!snap) {
      console.log("No data associated with the event");
      return;
    }

    const booking = snap.data();
    const bookingId = event.params.bookingId;

    // Only notify for pending bookings
    if (booking.bookingStatusCode !== "P") {
      console.log("Booking is not pending, skipping worker notification.");
      return null;
    }

    // Get the selected worker/agent details
    const agent = booking.agent;
    if (!agent || !agent.uid) {
      console.log("No worker assigned to this booking.");
      return null;
    }

    const workerId = agent.uid;
    const serviceName = booking.service?.name || "Service";
    const serviceNameAr = booking.service?.name_ar || serviceName;
    const customerName = booking.customer?.name || "A customer";

    // Fetch worker details from users collection
    let workerData;
    try {
      const workerDoc = await admin
        .firestore()
        .collection("users")
        .doc(workerId)
        .get();

      if (!workerDoc.exists) {
        console.log("Worker document not found.");
        return null;
      }
      workerData = workerDoc.data();
    } catch (error) {
      console.error("Error fetching worker data:", error);
      return null;
    }

    const fcmToken = workerData?.fcmToken;
    const lanCode = workerData?.lanCode || "en";

    if (!fcmToken || fcmToken.trim() === "") {
      console.log("Worker has no valid FCM token.");
      return null;
    }

    // Prepare notification messages
    await sendAndStoreNotification({
      targetRole: "technician",
      targetId: workerId,
      titleEn: "New Booking Request!",
      titleAr: "طلب حجز جديد!",
      bodyEn: `A customer has requested ${serviceName}. Please review and accept the booking.`,
      bodyAr: `طلب عميل ${serviceNameAr}. يرجى المراجعة وقبول الحجز.`,
      data: {
        targetRole: "technician",
        category: "booking",
        bookingId: bookingId,
        serviceName: serviceName,
        serviceNameAr: serviceNameAr,
        customerName: customerName,
        isAdmin: "false",
      },
      fcmToken: fcmToken,
      lanCode: lanCode,
    });

    return null;
  }
);

exports.notifyAdminsOnTipPayoutRequest = onDocumentWritten(
  "tipping/{walletId}",
  async (event) => {
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();
    const walletId = event.params.walletId;

    if (!afterData) {
      console.log("Document deleted, skipping...");
      return;
    }

    // Check if payoutRequested changed from false to true
    const wasRequested = beforeData?.payoutRequested === true;
    const isRequestedNow = afterData.payoutRequested === true;

    if (!isRequestedNow || wasRequested) {
      console.log("No new payout request detected, skipping...");
      return;
    }

    const agentName = afterData.agentName || "A worker";
    const agentId = afterData.agentId;
    const totalTip = afterData.totalTip || 0;

    // Fetch all admin users
    try {
      const adminUsersDocs = await getAllAdminUsers();

      const tokensWithLanguage = [];
      adminUsersSnapshot.forEach((doc) => {
        const user = doc.data();
        if (user.fcmToken && user.fcmToken.trim() !== "") {
          tokensWithLanguage.push({
            uid: doc.id,
            token: user.fcmToken,
            lanCode: user.lanCode || "en",
          });
        }
      });

      if (tokensWithLanguage.length === 0) {
        console.log("No admin tokens found.");
        return null;
      }

      // Send notification to each admin
      const results = [];
      for (const { uid, token, lanCode } of tokensWithLanguage) {
        await sendAndStoreNotification({
          targetRole: "admin",
          targetId: uid,
          titleEn: "Tip Payout Request",
          titleAr: "طلب سحب إكرامية",
          bodyEn: `${agentName} requested a tip payout of ₹${totalTip}. Please review and approve.`,
          bodyAr: `${agentName} طلب سحب إكرامية بمبلغ ${totalTip}. يرجى المراجعة والموافقة.`,
          data: {
            targetRole: "admin",
            category: "tip_payout",
            walletId: walletId,
            agentId: agentId,
            agentName: agentName,
            amount: totalTip.toString(),
            isAdmin: "true",
          },
          fcmToken: token,
          lanCode: lanCode,
        });
      }

      console.log(
        `Notified ${results.filter((r) => r.success).length
        } admins about tip payout request.`
      );
    } catch (error) {
      console.error("Error sending admin notifications:", error);
      return null;
    }
  }
);

exports.notifyWorkerOnTipPayoutProcessed = onDocumentWritten(
  "tipping/{walletId}",
  async (event) => {
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();
    const walletId = event.params.walletId;

    if (!afterData) {
      console.log("Document deleted, skipping...");
      return;
    }

    // Check if payoutRequested changed from true to false (payout processed)
    const wasRequested = beforeData?.payoutRequested === true;
    const isRequestedNow = afterData.payoutRequested === true;

    if (!wasRequested || isRequestedNow) {
      console.log("No payout processing detected, skipping...");
      return;
    }

    const agentId = afterData.agentId;
    const totalTip = afterData.totalTip || 0;

    if (!agentId) {
      console.log("No agentId found in tipping document.");
      return;
    }

    // Fetch worker details from users collection
    let workerData;
    try {
      const workerDoc = await admin
        .firestore()
        .collection("users")
        .doc(agentId)
        .get();

      if (!workerDoc.exists) {
        console.log("Worker document not found.");
        return;
      }
      workerData = workerDoc.data();
    } catch (error) {
      console.error("Error fetching worker data:", error);
      return;
    }

    const fcmToken = workerData?.fcmToken;
    const lanCode = workerData?.lanCode || "en";

    if (!fcmToken || fcmToken.trim() === "") {
      console.log("Worker has no valid FCM token.");
      return;
    }

    // Prepare notification
    const notificationTitle = {
      en: "Tip Payout Processed",
      ar: "تم معالجة سحب الإكرامية",
    };

    const notificationBody = {
      en: `Your tip payout of ₹${totalTip} has been processed successfully. The amount will be transferred to your account shortly.`,
      ar: `تم معالجة سحب الإكرامية بمبلغ ₹${totalTip} بنجاح. سيتم تحويل المبلغ إلى حسابك قريبًا.`,
    };

    const title = notificationTitle[lanCode] || notificationTitle["en"];
    const body = notificationBody[lanCode] || notificationBody["en"];

    await sendAndStoreNotification({
      targetRole: "technician",
      targetId: agentId,
      titleEn: notificationTitle["en"],
      titleAr: notificationTitle["ar"],
      bodyEn: notificationBody["en"],
      bodyAr: notificationBody["ar"],
      data: {
        targetRole: "technician",
        category: "tip_payout",
        walletId: walletId,
        amount: totalTip.toString(),
        isAdmin: "false",
      },
      fcmToken: fcmToken,
      lanCode: lanCode,
    });
  }
);
// ============================================
// Send Custom Notification to Technicians (Bilingual)
// ============================================
exports.sendCustomNotificationToTechnicians = onDocumentCreated(
  "notification_queue/{docId}",
  async (event) => {
    const snap = event.data;
    if (!snap) {
      console.log("No data associated with the event");
      return;
    }

    const data = snap.data();
    const docId = event.params.docId;
    const recipientId = data.recipientId;
    const targetRole = data.targetRole || "technician"; // Default to technician for backward compatibility

    // Support both old format (single language) and new format (bilingual)
    const titleEn = data.titleEn || data.title || null;
    const bodyEn = data.bodyEn || data.body || null;
    const titleAr = data.titleAr || null;
    const bodyAr = data.bodyAr || null;

    if (!recipientId) {
      console.log("Missing recipientId in notification_queue");
      await snap.ref.update({
        processed: true,
        error: "Missing recipientId",
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return;
    }

    // Validate at least one language has content
    if ((!titleEn && !titleAr) || (!bodyEn && !bodyAr)) {
      console.log(
        "Missing required fields - at least one language must have title and body"
      );
      await snap.ref.update({
        processed: true,
        error: "Missing content in both languages",
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return;
    }

    try {
      // Determine collection based on role
      const collectionName = targetRole === "customer" ? "customers" : "users";

      // Get recipient's FCM token and language preference
      const recipientDoc = await admin
        .firestore()
        .collection(collectionName)
        .doc(recipientId)
        .get();

      if (!recipientDoc.exists) {
        console.log(`${targetRole} document not found for ID: ${recipientId}`);
        await snap.ref.update({
          processed: true,
          error: `${targetRole} not found`,
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return;
      }

      const recipientData = recipientDoc.data();
      const fcmToken = recipientData?.fcmToken;
      const lanCode = recipientData?.lanCode || "en";

      if (!fcmToken || fcmToken.trim() === "") {
        console.log(`No valid FCM token for ${targetRole}: ${recipientId}`);
        await snap.ref.update({
          processed: true,
          error: "No valid FCM token",
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return;
      }

      // Select notification text based on recipient's language preference
      let notificationTitle, notificationBody;

      if (lanCode === "ar" && titleAr && bodyAr) {
        notificationTitle = titleAr;
        notificationBody = bodyAr;
        console.log(
          `Sending Arabic notification to ${targetRole} ${recipientId}`
        );
      } else if (titleEn && bodyEn) {
        notificationTitle = titleEn;
        notificationBody = bodyEn;
        console.log(
          `Sending English notification to ${targetRole} ${recipientId}`
        );
      } else if (titleAr && bodyAr) {
        notificationTitle = titleAr;
        notificationBody = bodyAr;
        console.log(
          `Sending Arabic notification to ${targetRole} ${recipientId}`
        );
      } else {
        throw new Error("No valid notification content available");
      }

      // Send FCM notification
      const message = {
        notification: {
          title: notificationTitle,
          body: notificationBody,
        },
        data: {
          type: "custom",
          sentAt: new Date().toISOString(),
          recipientId: recipientId,
          language: lanCode,
          isAdmin: "false",
          targetRole: targetRole,
        },
        token: fcmToken,
        android: {
          priority: "high",
          notification: {
            sound: "default",
            channelId: "abo_glumbo_channel",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        apns: {
          headers: {
            "apns-priority": "10",
          },
          payload: {
            aps: {
              alert: {
                title: notificationTitle,
                body: notificationBody,
              },
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      const response = await admin.messaging().send(message);

      // Update notification in Firestore with both language versions
      const notificationRef = admin
        .firestore()
        .collection(collectionName)
        .doc(recipientId)
        .collection("notifications")
        .doc();

      await notificationRef.set({
        titleEn: titleEn,
        bodyEn: bodyEn,
        titleAr: titleAr,
        bodyAr: bodyAr,
        // Store the sent notification text for history
        sentTitle: notificationTitle,
        sentBody: notificationBody,
        sentLanguage: lanCode,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
        type: "custom",
        fcmMessageId: response,
      });

      // Mark queue document as processed
      await snap.ref.update({
        processed: true,
        fcmMessageId: response,
        sentLanguage: lanCode,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(
        `✅ Custom notification sent to ${targetRole} ${recipientId} in ${lanCode}. MessageId: ${response}`
      );
    } catch (error) {
      console.error(
        `❌ Error sending custom notification to ${recipientId}:`,
        error
      );
      await snap.ref.update({
        processed: true,
        error: error.message,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }
);

exports.notifyCustomerOnWorkerCancellation = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const beforeSnap = event.data.before;
    const afterSnap = event.data.after;

    if (!beforeSnap || !afterSnap) {
      console.log("No data associated with the event");
      return;
    }

    const beforeData = beforeSnap.data();
    const afterData = afterSnap.data();

    // Check if cancelledWorkerUids array changed (new cancellation)
    const beforeCancelledCount = beforeData.cancelledWorkerUids?.length || 0;
    const afterCancelledCount = afterData.cancelledWorkerUids?.length || 0;

    // Only proceed if a worker was just added to cancelledWorkerUids
    if (afterCancelledCount <= beforeCancelledCount) {
      return;
    }

    try {
      // Get the customer data to retrieve FCM token
      const customerId = afterData.customer.uid || afterData.customer.uid;

      if (!customerId) {
        console.log("Customer ID not found in booking data");
        return;
      }

      const customerDoc = await db
        .collection("customers")
        .doc(customerId)
        .get();

      if (!customerDoc.exists) {
        console.log(`Customer document not found for ID: ${customerId}`);
        return;
      }

      const customerData = customerDoc.data();
      const customerFcmToken = customerData.fcmToken;

      if (!customerFcmToken) {
        console.log("Customer FCM token not found");
        return;
      }

      // Get the worker details who just cancelled from CancelledWorkers array
      const cancelledWorkers = afterData.cancelledWorkers || [];
      const lastCancelledWorker = cancelledWorkers[cancelledWorkers.length - 1];

      if (!lastCancelledWorker) {
        console.log("No cancelled Technician found");
        return;
      }

      // Get service name from ServiceModel
      const serviceData = afterData.service;
      const serviceName =
        customerData.lanCode === "ar"
          ? serviceData.name_ar || serviceData.name
          : serviceData.name;

      const customerLanCode = customerData.lanCode || "en";

      await sendAndStoreNotification({
        targetRole: "customer",
        targetId: customerId,
        titleEn: "Booking Rejected",
        titleAr: "تم رفض الحجز",
        bodyEn: `A Technician rejected your booking for ${serviceName}.`,
        bodyAr: `لقد قام الفني برفض حجزك ل ${serviceName}.`,
        data: {
          bookingId: afterData.id,
          bookingStatusCode: afterData.bookingStatusCode,
          cancelledWorkerName: lastCancelledWorker.agentName,
          cancelledWorkerCount: afterCancelledCount.toString(),
          bookingDateTime: afterData.bookingDateTime.toDate().toISOString(),
        },
        fcmToken: customerFcmToken,
        lanCode: customerLanCode,
      });

      console.log(
        `✅ Customer notification sent for booking ${afterData.id} - Worker ${lastCancelledWorker.agentName} rejected`
      );
    } catch (error) {
      console.error(
        `❌ Error sending customer cancellation notification: ${error}`
      );
    }
  }
);

exports.notifyAdminsOnWorkerCancellation = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const beforeSnap = event.data.before;
    const afterSnap = event.data.after;

    if (!beforeSnap || !afterSnap) {
      console.log("No data associated with the event");
      return;
    }

    const beforeData = beforeSnap.data();
    const afterData = afterSnap.data();

    // Check if cancelledWorkerUids array changed (new cancellation)
    const beforeCancelledCount = beforeData.cancelledWorkerUids?.length || 0;
    const afterCancelledCount = afterData.cancelledWorkerUids?.length || 0;

    // Only proceed if a worker was just added to cancelledWorkerUids
    if (afterCancelledCount <= beforeCancelledCount) {
      return;
    }

    try {
      // Get the worker details who just cancelled from CancelledWorkers array
      const cancelledWorkers = afterData.cancelledWorkers || [];
      const lastCancelledWorker = cancelledWorkers[cancelledWorkers.length - 1];

      if (!lastCancelledWorker) {
        console.log("No cancelled Technician found");
        return;
      }

      // Get service name from ServiceModel
      const serviceData = afterData.service;
      const serviceName = serviceData.name;
      const serviceNameAr = serviceData.name_ar || serviceData.name;

      // Get customer name
      const customerName = afterData.customer.name;

      // Fetch all admin users with FCM tokens
      const adminUsersDocs = await getAllAdminUsers();
      const adminsWithTokens = adminUsersDocs.filter(
        (doc) => doc.data().fcmToken && doc.data().fcmToken.trim() !== ""
      );

      if (adminsWithTokens.length === 0) {
        console.log("No admin users found with FCM tokens");
        return;
      }

      // Send notification to each admin
      for (const adminDoc of adminsWithTokens) {
        const adminData = adminDoc.data();
        const adminFcmToken = adminData.fcmToken;
        const adminLanCode = adminData.lanCode || "en";

        await sendAndStoreNotification({
          targetRole: "admin",
          targetId: adminDoc.id,
          titleEn: "Technician Cancelled A Booking",
          titleAr: "الفني قام برفض الحجز",
          bodyEn: `${lastCancelledWorker.agentName} rejected booking for ${serviceName} from ${customerName}. Please review and assign a new Technician.`,
          bodyAr: `${lastCancelledWorker.agentName} رفض حجزك ل${serviceNameAr} من ${customerName}. يرجى مراجعة وتعيين فني جديد.`,
          data: {
            bookingId: afterData.id,
            bookingStatusCode: afterData.bookingStatusCode,
            cancelledWorkerName: lastCancelledWorker.agentName,
            cancelledWorkerUid: lastCancelledWorker.uid,
            cancelledWorkerCount: afterCancelledCount.toString(),
            customerName: customerName,
            serviceName: serviceName,
            bookingDateTime: afterData.bookingDateTime.toDate().toISOString(),
            totalCancelledWorkers: afterCancelledCount.toString(),
          },
          fcmToken: adminFcmToken,
          lanCode: adminLanCode,
        });
      }
      console.log(
        `✅ Admin notifications sent for booking ${afterData.id} - Worker ${lastCancelledWorker.agentName} rejected`
      );
    } catch (error) {
      console.error(
        `❌ Error sending admin cancellation notification: ${error}`
      );
    }
  }
);

exports.notifyWorkersOnCustomerCancellation = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const beforeSnap = event.data.before;
    const afterSnap = event.data.after;

    if (!beforeSnap || !afterSnap) {
      console.log("No data associated with the event");
      return;
    }

    const beforeData = beforeSnap.data();
    const afterData = afterSnap.data();

    // Check if booking status changed to XC (customer cancelled)
    if (
      beforeData.bookingStatusCode !== afterData.bookingStatusCode ||
      afterData.bookingStatusCode !== "XC"
    ) {
      return;
    }

    try {
      // Get service name from ServiceModel
      const serviceData = afterData.service;
      const serviceName = serviceData.name;
      const serviceNameAr = serviceData.name_ar || serviceData.name;

      // Get customer name
      const customerName = afterData.customer.name;

      // Get list of workers who were assigned or cancelled this booking
      const cancelledWorkerUids = afterData.cancelledWorkerUids || [];
      const agent = afterData.agent;

      // Collect all worker UIDs (both cancelled workers and assigned agent)
      let workerUids = [...cancelledWorkerUids];
      if (agent && agent.uid && !workerUids.includes(agent.uid)) {
        workerUids.push(agent.uid);
      }

      if (workerUids.length === 0) {
        console.log("No workers to notify");
        return;
      }

      // Fetch all workers who were involved with this booking
      const workersSnapshot = await db
        .collection("users")
        .where("__name__", "in", workerUids.slice(0, 10)) // Firestore limits 'in' to 10 items
        .get();

      if (workersSnapshot.empty) {
        console.log("No workers found with FCM tokens");
        return;
      }

      // Send notification to each worker
      for (const workerDoc of workersSnapshot.docs) {
        const workerData = workerDoc.data();
        const workerFcmToken = workerData.fcmToken;
        const workerLanCode = workerData.lanCode || "en";

        if (!workerFcmToken) continue;

        await sendAndStoreNotification({
          targetRole: "technician",
          targetId: workerDoc.id,
          titleEn: "Booking Cancelled by Customer",
          titleAr: "تم إلغاء الحجز من قبل العميل",
          bodyEn: `Customer ${customerName} cancelled their booking for ${serviceName}. You can no longer accept this booking.`,
          bodyAr: `العميل ${customerName} قام بإلغاء حجز ${serviceNameAr}. لن تتمكن من قبول هذا الحجز.`,
          data: {
            bookingId: afterData.id,
            bookingStatusCode: afterData.bookingStatusCode,
            customerName: customerName,
            serviceName: serviceName,
            bookingDateTime: afterData.bookingDateTime.toDate().toISOString(),
            cancelledBy: "customer",
          },
          fcmToken: workerFcmToken,
          lanCode: workerLanCode,
        });
      }
      console.log(
        `✅ Worker notifications sent for booking ${afterData.id} - Customer cancelled`
      );
    } catch (error) {
      console.error(
        `❌ Error sending worker cancellation notification: ${error}`
      );
    }
  }
);

exports.notifyAdminsOnCustomerCancellation = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const beforeSnap = event.data.before;
    const afterSnap = event.data.after;

    if (!beforeSnap || !afterSnap) {
      console.log("No data associated with the event");
      return;
    }

    const beforeData = beforeSnap.data();
    const afterData = afterSnap.data();

    // Check if booking status changed to XC (customer cancelled)
    if (
      beforeData.bookingStatusCode !== afterData.bookingStatusCode ||
      afterData.bookingStatusCode !== "XC"
    ) {
      return;
    }

    try {
      // Get service name from ServiceModel
      const serviceData = afterData.service;
      const serviceName = serviceData.name;
      const serviceNameAr = serviceData.name_ar || serviceData.name;

      // Get customer name
      const customerName = afterData.customer.name;

      // Get cancellation reason if available
      const cancellationReason = afterData.cancellationReason || "Not provided";

      // Fetch all admin users with FCM tokens
      const adminUsersDocs = await getAllAdminUsers();
      const adminsWithTokens = adminUsersDocs.filter(
        (doc) => doc.data().fcmToken && doc.data().fcmToken.trim() !== ""
      );

      if (adminsWithTokens.length === 0) {
        console.log("No admin users found with FCM tokens");
        return;
      }

      // Send notification to each admin
      for (const adminDoc of adminsWithTokens) {
        const adminData = adminDoc.data();
        const adminFcmToken = adminData.fcmToken;
        const adminLanCode = adminData.lanCode || "en";

        await sendAndStoreNotification({
          targetRole: "admin",
          targetId: adminDoc.id,
          titleEn: "Booking Cancelled by Customer",
          titleAr: "تم إلغاء الحجز من قبل العميل",
          bodyEn: `Customer ${customerName} cancelled their booking for ${serviceName}. Reason: ${cancellationReason}`,
          bodyAr: `العميل ${customerName} قام بإلغاء حجز ${serviceNameAr}. السبب: ${cancellationReason}`,
          data: {
            bookingId: afterData.id,
            bookingStatusCode: afterData.bookingStatusCode,
            customerName: customerName,
            serviceName: serviceName,
            bookingDateTime: afterData.bookingDateTime.toDate().toISOString(),
            cancellationReason: cancellationReason,
            cancelledBy: "customer",
          },
          fcmToken: adminFcmToken,
          lanCode: adminLanCode,
        });
      }
      console.log(
        `✅ Admin notifications sent for booking ${afterData.id} - Customer cancelled`
      );
    } catch (error) {
      console.error(
        `❌ Error sending admin cancellation notification: ${error}`
      );
    }
  }
);
exports.notifyAdminsOnNewWorkerSignup = onDocumentCreated(
  "users/{userId}",
  async (event) => {
    const snap = event.data;
    if (!snap) {
      console.log("No data associated with the event");
      return;
    }

    const worker = snap.data();
    const userId = event.params.userId;

    // Only notify for new workers (not admins or customers)
    if (worker.isAdmin === true) {
      console.log("User is admin, skipping notification.");
      return null;
    }

    // Optional: Check if worker has job roles (indicating they're a worker, not a customer)
    if (!worker.jobRoles || worker.jobRoles.length === 0) {
      console.log(
        "User has no job roles, might not be a Technician yet. Skipping notification."
      );
      return null;
    }

    const workerName = worker.name || "A new worker";
    const workerPhone = worker.phone || "Not provided";
    const workerEmail = worker.email || "Not provided";
    const jobRoles = worker.jobRoles
      ? worker.jobRoles.join(", ")
      : "Not specified";
    const districtName = worker.districtName || "Not specified";

    try {
      // Fetch all admin users
      const adminUsersDocs = await getAllAdminUsers();

      const tokensWithLanguage = [];
      adminUsersSnapshot.forEach((doc) => {
        const user = doc.data();
        if (user.fcmToken && user.fcmToken.trim() !== "") {
          tokensWithLanguage.push({
            token: user.fcmToken,
            lanCode: user.lanCode || "en",
          });
        }
      });

      if (tokensWithLanguage.length === 0) {
        console.log("No admin tokens found.");
        return null;
      }

      const results = [];

      // Send notification to each admin
      for (const { token, lanCode } of tokensWithLanguage) {
        try {
          const message = {
            notification: {
              title:
                lanCode === "ar"
                  ? "فني جديد انضم!"
                  : "New Technician Signed Up!",
              body:
                lanCode === "ar"
                  ? `${workerName} قام بالتسجيل كفني جديد. يرجى مراجعة الملف الشخصي والموافقة عليه`
                  : `${workerName} has signed up as a new Technician. Please review their profile and approve`,
            },
            data: {
              targetRole: "admin",
              category: "worker_signup",
              workerId: userId,
              workerName: workerName,
              workerPhone: workerPhone,
              jobRoles: jobRoles,
              districtName: districtName,
            },
            token: token,
          };

          const response = await admin.messaging().send(message);
          results.push({ token, success: true, messageId: response });
          console.log(
            `Notification sent to admin with token: ${token.substring(
              0,
              20
            )}...`
          );
        } catch (error) {
          results.push({ token, success: false, error: error.message });
          console.error(`Failed to send to token: ${error.message}`);
        }
      }

      console.log(
        `Notified ${results.filter((r) => r.success).length
        } admins about new worker signup: ${workerName}`
      );
    } catch (error) {
      console.error("Error sending admin notifications:", error);
    }

    return null;
  }
);
// ============================================
// Warranty Request Notifications
// ============================================
exports.notifyOnWarrantyRequestStatusChange = onDocumentWritten(
  "bookings/{bookingId}",
  async (event) => {
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();
    const bookingId = event.params.bookingId;

    if (!afterData) {
      console.log("Booking document deleted, skipping warranty check...");
      return;
    }

    const beforeWarranty = beforeData?.warranty;
    const afterWarranty = afterData?.warranty;

    // Check if warranty exists in afterData
    if (!afterWarranty) {
      return;
    }

    // Get warranty status codes
    const beforeStatusCode = beforeWarranty?.warrantyStatusCode;
    const afterStatusCode = afterWarranty.warrantyStatusCode;

    // Determine status change based on warrantyStatusCode
    let status = null;
    let notificationData = {};

    // 1. Warranty Created (bookingStatusCode changed to C, warranty added with status A)
    if (!beforeWarranty && afterWarranty && afterStatusCode === "A") {
      status = "warranty_available";
      console.log(
        `Warranty created for booking ${bookingId} with status A (Available)`
      );
    }
    // 2. Customer Requested Repair (warrantyStatusCode changed from A to R)
    else if (beforeStatusCode === "A" && afterStatusCode === "R") {
      status = "repair_requested";
      console.log(
        `Customer requested repair for booking ${bookingId} (A -> R)`
      );
    }
    // 3. Warranty Accepted by Technician/Admin (warrantyStatusCode changed to S - Accepted/Started)
    else if (
      (beforeStatusCode === "R" || beforeStatusCode === "A") &&
      afterStatusCode === "S"
    ) {
      status = "warranty_accepted";
      console.log(
        `Warranty accepted for booking ${bookingId} (${beforeStatusCode} -> S)`
      );
    }
    // 4. Warranty Completed (warrantyStatusCode changed to C)
    else if (afterStatusCode === "C" && beforeStatusCode !== "C") {
      status = "warranty_completed";
      console.log(
        `Warranty completed for booking ${bookingId} (${beforeStatusCode} -> C)`
      );
    }
    // 5. Admin Rejected Warranty (warrantyStatusCode changed to X)
    else if (afterStatusCode === "X" && beforeStatusCode !== "X") {
      status = "warranty_rejected";
      console.log(
        `Warranty rejected by admin for booking ${bookingId} (${beforeStatusCode} -> X)`
      );
    }
    // 6. Warranty Expired (warrantyStatusCode changed to E)
    else if (afterStatusCode === "E" && beforeStatusCode !== "E") {
      status = "warranty_expired";
      console.log(
        `Warranty expired for booking ${bookingId} (${beforeStatusCode} -> E)`
      );
    }
    // 7. Technician Rejected (rejectedTechnicians array grew)
    else if (
      (beforeWarranty?.rejectedTechnicians?.length || 0) <
      (afterWarranty.rejectedTechnicians?.length || 0)
    ) {
      status = "technician_rejected";
      const latestRejection =
        afterWarranty.rejectedTechnicians[
        afterWarranty.rejectedTechnicians.length - 1
        ];
      notificationData = {
        rejectedTechnicianName: latestRejection?.name || "Technician",
        rejectedTechnicianUid: latestRejection?.uid || "",
        rejectionReason: latestRejection?.reason || "Not specified",
      };
      console.log(
        `Technician ${latestRejection?.name} rejected warranty for booking ${bookingId}`
      );
    }
    // 8. Warranty-based Tracking Started
    // Check if isStartTracking changed and tracking timestamps are after warranty.acceptedAt
    else if (
      !beforeData?.isStartTracking &&
      afterData.isStartTracking &&
      afterWarranty.acceptedAt &&
      afterData.trackingStartedAt
    ) {
      // Convert timestamps for comparison
      const acceptedAtTime = afterWarranty.acceptedAt.toDate
        ? afterWarranty.acceptedAt.toDate().getTime()
        : new Date(afterWarranty.acceptedAt).getTime();
      const trackingStartedTime = afterData.trackingStartedAt.toDate
        ? afterData.trackingStartedAt.toDate().getTime()
        : new Date(afterData.trackingStartedAt).getTime();

      // Only send notification if tracking started after warranty was accepted
      if (trackingStartedTime > acceptedAtTime) {
        status = "warranty_tracking_started";
        console.log(
          `Warranty-based tracking started for booking ${bookingId} (tracking started after warranty acceptance)`
        );
      }
    }
    // 9. Warranty-based Tracking Stopped
    else if (
      beforeData?.isStartTracking &&
      !afterData.isStartTracking &&
      afterWarranty.acceptedAt &&
      afterData.trackingStoppedAt
    ) {
      // Convert timestamps for comparison
      const acceptedAtTime = afterWarranty.acceptedAt.toDate
        ? afterWarranty.acceptedAt.toDate().getTime()
        : new Date(afterWarranty.acceptedAt).getTime();
      const trackingStoppedTime = afterData.trackingStoppedAt.toDate
        ? afterData.trackingStoppedAt.toDate().getTime()
        : new Date(afterData.trackingStoppedAt).getTime();

      // Only send notification if tracking stopped after warranty was accepted
      if (trackingStoppedTime > acceptedAtTime) {
        status = "warranty_tracking_stopped";
        console.log(
          `Warranty-based tracking stopped for booking ${bookingId} (tracking stopped after warranty acceptance)`
        );
      }
    }
    // 10. Warranty Technician Assigned/Reassigned
    // Only notify if assignedTechnicianId is different from original agent.uid
    // AND status changed from R to S
    else if (
      beforeStatusCode === "R" &&
      afterStatusCode === "S" &&
      afterWarranty.assignedTechnicianId &&
      afterWarranty.assignedTechnicianId !== afterData.agent?.uid
    ) {
      status = "warranty_technician_assigned";
      console.log(
        `Warranty technician ${afterWarranty.assignedTechnicianId} assigned to booking ${bookingId} (different from original agent ${afterData.agent?.uid})`
      );
    }

    if (!status) {
      return;
    }

    console.log(
      `Warranty status changed to ${status} for booking ${bookingId}`
    );

    const customerId = afterData.customer?.uid;
    const customerName = afterData.customer?.name || "Customer";
    const serviceName = afterData.service?.name || "Service";
    const serviceNameAr = afterData.service?.name_ar || serviceName;
    const workerId = afterWarranty.assignedTechnicianId || afterData.agent?.uid;

    // Fetch customer data for notification
    let customerData;
    if (customerId) {
      try {
        const customerDoc = await admin
          .firestore()
          .collection("customers")
          .doc(customerId)
          .get();

        if (customerDoc.exists) {
          customerData = customerDoc.data();
        }
      } catch (error) {
        console.error("Error fetching customer data:", error);
      }
    }

    // Fetch admin users
    let adminTokens = [];
    try {
      const adminUsersDocs = await getAllAdminUsers();

      adminTokens = adminSnapshot.docs
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
    } catch (error) {
      console.error("Error fetching admin users:", error);
    }

    // Status-specific messages
    const statusMessages = {
      warranty_available: {
        customer: {
          en: "Your booking is now covered by warranty. You can request free repair within 7 days if needed.",
          ar: "حجزك الآن مشمول بالضمان. يمكنك طلب الإصلاح المجاني خلال 7 أيام إذا لزم الأمر.",
        },
        admin: {
          en: `Warranty activated for ${serviceName} - Customer: ${customerName}`,
          ar: `تم تفعيل الضمان لـ ${serviceNameAr} - العميل: ${customerName}`,
        },
      },
      repair_requested: {
        customer: {
          en: "Your warranty repair request has been submitted. We will assign a technician soon.",
          ar: "تم تقديم طلب إصلاح الضمان الخاص بك. سنقوم بتعيين فني قريبًا.",
        },
        admin: {
          en: `${customerName} requested warranty repair for ${serviceName}`,
          ar: `${customerName} طلب إصلاح الضمان لـ ${serviceNameAr}`,
        },
      },
      warranty_accepted: {
        customer: {
          en: "Your warranty repair request has been accepted. A technician will contact you soon.",
          ar: "تم قبول طلب إصلاح الضمان الخاص بك. سيتصل بك فني قريبًا.",
        },
        admin: {
          en: `Warranty repair accepted for ${serviceName} - Customer: ${customerName}`,
          ar: `تم قبول إصلاح الضمان لـ ${serviceNameAr} - العميل: ${customerName}`,
        },
      },
      warranty_tracking_started: {
        customer: {
          en: "The technician is on the way for your warranty repair. You can now track their location.",
          ar: "الفني في الطريق لإصلاح الضمان الخاص بك. يمكنك الآن تتبع موقعه.",
        },
        admin: {
          en: `Technician started tracking for warranty repair - ${serviceName}`,
          ar: `بدأ الفني التتبع لإصلاح الضمان - ${serviceNameAr}`,
        },
      },
      warranty_tracking_stopped: {
        customer: {
          en: "The technician has arrived at your location for warranty repair.",
          ar: "وصل الفني إلى موقعك لإصلاح الضمان.",
        },
        admin: {
          en: `Technician arrived for warranty repair - ${serviceName}`,
          ar: `وصل الفني لإصلاح الضمان - ${serviceNameAr}`,
        },
      },
      warranty_completed: {
        customer: {
          en: "Your warranty repair has been completed successfully. Thank you for using our service!",
          ar: "تم إكمال إصلاح الضمان الخاص بك بنجاح. شكرًا لاستخدام خدمتنا!",
        },
        admin: {
          en: `Warranty repair completed for ${serviceName} - Customer: ${customerName}`,
          ar: `تم إكمال إصلاح الضمان لـ ${serviceNameAr} - العميل: ${customerName}`,
        },
      },
      warranty_rejected: {
        customer: {
          en: "Your warranty repair request has been rejected by the administrator.",
          ar: "تم رفض طلب إصلاح الضمان الخاص بك من قبل المسؤول.",
        },
        admin: {
          en: `Warranty repair rejected for ${serviceName} - Customer: ${customerName}`,
          ar: `تم رفض إصلاح الضمان لـ ${serviceNameAr} - العميل: ${customerName}`,
        },
      },
      warranty_expired: {
        customer: {
          en: "Your warranty period has expired (7 days). You can no longer request repair under warranty.",
          ar: "انتهت فترة الضمان الخاصة بك (7 أيام). لم يعد بإمكانك طلب الإصلاح بموجب الضمان.",
        },
        admin: {
          en: `Warranty expired for ${serviceName} - Customer: ${customerName}`,
          ar: `انتهى الضمان لـ ${serviceNameAr} - العميل: ${customerName}`,
        },
      },
      technician_rejected: {
        customer: {
          en: `Technician ${notificationData.rejectedTechnicianName || "has"
            } declined your warranty repair request. We are assigning another technician.`,
          ar: `رفض الفني ${notificationData.rejectedTechnicianName || ""
            } طلب إصلاح الضمان الخاص بك. نحن نقوم بتعيين فني آخر.`,
        },
        admin: {
          en: `Technician ${notificationData.rejectedTechnicianName || "Unknown"
            } rejected warranty repair for ${serviceName}. Reason: ${notificationData.rejectionReason || "Not specified"
            }`,
          ar: `رفض الفني ${notificationData.rejectedTechnicianName || "غير معروف"
            } إصلاح الضمان لـ ${serviceNameAr}. السبب: ${notificationData.rejectionReason || "غير محدد"
            }`,
        },
      },
    };

    // Notify customer
    if (customerData?.fcmToken && customerData.fcmToken.trim() !== "") {
      const customerLanCode = customerData.lanCode || "en";

      await sendAndStoreNotification({
        targetRole: "customer",
        targetId: customerId,
        titleEn: "Warranty Update",
        titleAr: "تحديث الضمان",
        bodyEn:
          statusMessages[status]?.customer?.["en"] ||
          `Your warranty status has been updated`,
        bodyAr:
          statusMessages[status]?.customer?.["ar"] ||
          `تم تحديث حالة الضمان الخاصة بك`,
        data: {
          targetRole: "customer",
          category: "warranty",
          bookingId: bookingId,
          status: status,
          warrantyStatusCode: afterStatusCode,
          serviceName: serviceName,
          isWarranty: "true",
          ...notificationData,
        },
        fcmToken: customerData.fcmToken,
        lanCode: customerLanCode,
      });
    }

    // Notify admins
    if (adminTokens.length > 0) {
      for (const { uid, token, lanCode } of adminTokens) {
        await sendAndStoreNotification({
          targetRole: "admin",
          targetId: uid,
          titleEn: "Warranty Update",
          titleAr: "تحديث الضمان",
          bodyEn:
            statusMessages[status]?.admin?.["en"] ||
            `Warranty status updated for booking ${bookingId}`,
          bodyAr:
            statusMessages[status]?.admin?.["ar"] ||
            `تم تحديث حالة الضمان للحجز ${bookingId}`,
          data: {
            targetRole: "admin",
            category: "warranty",
            bookingId: bookingId,
            customerId: customerId || "",
            customerName: customerName,
            workerId: workerId || "",
            status: status,
            warrantyStatusCode: afterStatusCode,
            serviceName: serviceName,
            isWarranty: "true",
            isAdmin: "true",
            ...notificationData,
          },
          fcmToken: token,
          lanCode: lanCode,
        });
      }
    }

    // Note: Warranty technician assignment notifications are handled by
    // the separate notifyTechnicianOnWarrantyAssignment function to avoid duplicates

    return null;
  }
);

// ============================================
// Notify Admins on Warranty Escalation
// ============================================
exports.notifyAdminsOnWarrantyEscalation = onDocumentWritten(
  "bookings/{bookingId}",
  async (event) => {
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();
    const bookingId = event.params.bookingId;

    if (!afterData) {
      console.log("Booking document deleted, skipping escalation check...");
      return;
    }

    // Check if isEscalated changed from false/undefined to true
    const wasEscalated = beforeData?.isEscalated === true;
    const isEscalatedNow = afterData.isEscalated === true;

    if (!isEscalatedNow || wasEscalated) {
      return; // No escalation occurred
    }

    console.log(
      `Warranty request escalated for booking ${bookingId}. Notifying admins...`
    );

    const serviceName = afterData.service?.name || "Service";
    const customerName = afterData.customer?.name || "Customer";
    const warranty = afterData.warranty;

    // Determine escalation reason
    let escalationReason = "staying unchanged (unattended) for a long time";
    if (
      warranty?.rejectedTechnicians &&
      warranty.rejectedTechnicians.length > 0
    ) {
      escalationReason =
        "the original technician cancelled/rejected the request";
    }

    // Fetch all admin users
    let adminTokens = [];
    try {
      const adminUsersDocs = await getAllAdminUsers();

      adminTokens = adminSnapshot.docs
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
    } catch (error) {
      console.error("Error fetching admin users:", error);
      return;
    }

    if (adminTokens.length === 0) {
      console.log("No admin tokens found for escalation notification.");
      return;
    }

    // Notification messages
    const titleEn = "⚠️ Warranty Request Escalated";
    const titleAr = "⚠️ تم تصعيد طلب الضمان";

    const bodyEn = `A warranty request for "${serviceName}" from ${customerName} requires your attention.\n\nReason: This request has been ${escalationReason}.\n\nActions Available:\n✅ Approve Rejection: Confirm the technician's decision and close the request.\n🔁 Assign Alternate Technician: Use the "Assign" option to re-assign the job to another technician.`;

    const bodyAr = `طلب ضمان لـ "${serviceName}" من ${customerName} يتطلب انتباهك.\n\nالسبب: تم ${escalationReason === "staying unchanged (unattended) for a long time"
      ? "ترك هذا الطلب دون تغيير (غير مُعالج) لفترة طويلة"
      : "إلغاء/رفض الطلب من قبل الفني الأصلي"
      }.\n\nالإجراءات المتاحة:\n✅ الموافقة على الرفض: تأكيد قرار الفني وإغلاق الطلب.\n🔁 تعيين فني بديل: استخدم خيار "تعيين" لإعادة تعيين العمل لفني آخر.`;

    // Send notification to each admin
    for (const { uid, token, lanCode } of adminTokens) {
      await sendAndStoreNotification({
        targetRole: "admin",
        targetId: uid,
        titleEn: titleEn,
        titleAr: titleAr,
        bodyEn: bodyEn,
        bodyAr: bodyAr,
        data: {
          targetRole: "admin",
          category: "warranty_escalation",
          bookingId: bookingId,
          customerId: afterData.customer?.uid || "",
          customerName: customerName,
          serviceName: serviceName,
          escalationReason: escalationReason,
          isWarranty: "true",
          isAdmin: "true",
        },
        fcmToken: token,
        lanCode: lanCode,
      });
    }

    console.log(
      `✅ Escalation notifications sent to ${adminTokens.length} admin(s) for booking ${bookingId}`
    );

    return null;
  }
);

// ============================================
// Counter Offer Notifications
// ============================================
exports.notifyOnCounterOfferCreated = onDocumentCreated(
  "counter_offers/{offerId}",
  async (event) => {
    const offerId = event.params.offerId;
    const offerData = event.data?.data();

    if (!offerData) {
      console.log("No counter offer data found");
      return null;
    }

    const bookingId = offerData.bookingId;
    const proposedBy = offerData.proposedBy; // 'technician' or 'customer'
    const proposedByUid = offerData.proposedByUid;
    const proposedByName = offerData.proposedByName;

    console.log(`New counter offer created: ${offerId} for booking ${bookingId} by ${proposedBy}`);

    try {
      const bookingDoc = await db.collection("bookings").doc(bookingId).get();
      if (!bookingDoc.exists) {
        console.log(`Booking ${bookingId} not found`);
        return null;
      }

      const bookingData = bookingDoc.data();
      const customer = bookingData.customer;
      const agent = bookingData.agent;

      let targetRole, targetId, fcmToken, lanCode;

      if (proposedBy === 'technician') {
        targetRole = 'customer';
        targetId = customer?.uid;
        if (targetId) {
          const customerDoc = await db.collection("customers").doc(targetId).get();
          if (customerDoc.exists) {
            const customerData = customerDoc.data();
            fcmToken = customerData?.fcmToken;
            lanCode = customerData?.lanCode || 'en';
          }
        }
      } else if (proposedBy === 'customer') {
        targetRole = 'technician';
        targetId = agent?.uid;
        if (targetId) {
          const technicianDoc = await db.collection("users").doc(targetId).get();
          if (technicianDoc.exists) {
            const technicianData = technicianDoc.data();
            fcmToken = technicianData?.fcmToken;
            lanCode = technicianData?.lanCode || 'en';
          }
        }
      }

      if (!targetId || !fcmToken || fcmToken.trim() === '') {
        console.log(`No valid FCM token for ${targetRole} ${targetId}`);
        return null;
      }

      const serviceName = bookingData.service?.name || 'Service';
      const serviceNameAr = bookingData.service?.name_ar || serviceName;
      const proposedTime = offerData.proposedTime.toDate();
      const timeString = proposedTime.toLocaleString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
      });

      await sendAndStoreNotification({
        targetRole,
        targetId,
        titleEn: 'New Counter Offer',
        titleAr: 'اقتراح موعد جديد',
        bodyEn: `${proposedByName} has proposed a new time: ${timeString} for ${serviceName}`,
        bodyAr: `اقترح ${proposedByName} وقتاً جديداً: ${timeString} لـ ${serviceNameAr}`,
        data: {
          targetRole: targetRole,
          category: 'counter_offer',
          bookingId,
          offerId,
          proposedBy,
          proposedByUid,
          proposedTime: timeString,
          serviceName,
          serviceNameAr,
        },
        fcmToken,
        lanCode,
      });

      console.log(`Counter offer notification sent to ${targetRole} ${targetId}`);
    } catch (error) {
      console.error('Error sending counter offer notification:', error);
    }

    return null;
  }
);

exports.notifyOnCounterOfferStatusChange = onDocumentUpdated(
  "counter_offers/{offerId}",
  async (event) => {
    const beforeData = event.data.before?.data();
    const afterData = event.data.after?.data();
    const offerId = event.params.offerId;

    if (!beforeData || !afterData) {
      console.log("Counter offer data missing");
      return null;
    }

    const statusChanged = beforeData.status !== afterData.status;
    const newStatus = afterData.status;
    if (!statusChanged || !['accepted', 'rejected'].includes(newStatus)) {
      return null;
    }

    const bookingId = afterData.bookingId;
    const proposedBy = afterData.proposedBy;
    const proposedByUid = afterData.proposedByUid;
    const proposedByName = afterData.proposedByName;

    console.log(`Counter offer ${offerId} status changed to ${newStatus} for booking ${bookingId}`);

    try {
      const bookingDoc = await db.collection("bookings").doc(bookingId).get();
      if (!bookingDoc.exists) {
        console.log(`Booking ${bookingId} not found`);
        return null;
      }

      const bookingData = bookingDoc.data();
      const customer = bookingData.customer;
      const agent = bookingData.agent;

      let targetRole, targetId, fcmToken, lanCode;
      if (proposedBy === 'technician') {
        targetRole = 'customer';
        targetId = customer?.uid;
        if (targetId) {
          const customerDoc = await db.collection("customers").doc(targetId).get();
          if (customerDoc.exists) {
            const customerData = customerDoc.data();
            fcmToken = customerData?.fcmToken;
            lanCode = customerData?.lanCode || 'en';
          }
        }
      } else if (proposedBy === 'customer') {
        targetRole = 'technician';
        targetId = agent?.uid;
        if (targetId) {
          const technicianDoc = await db.collection("users").doc(targetId).get();
          if (technicianDoc.exists) {
            const technicianData = technicianDoc.data();
            fcmToken = technicianData?.fcmToken;
            lanCode = technicianData?.lanCode || 'en';
          }
        }
      }

      if (!targetId || !fcmToken || fcmToken.trim() === '') {
        console.log(`No valid FCM token for ${targetRole} ${targetId}`);
        return null;
      }

      const serviceName = bookingData.service?.name || 'Service';
      const serviceNameAr = bookingData.service?.name_ar || serviceName;
      const proposedTime = afterData.proposedTime.toDate();
      const timeString = proposedTime.toLocaleString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
      });
      const statusTextEn = newStatus === 'accepted' ? 'accepted' : 'rejected';
      const statusTextAr = newStatus === 'accepted' ? 'قبول' : 'رفض';

      await sendAndStoreNotification({
        targetRole,
        targetId,
        titleEn: 'Counter Offer Response',
        titleAr: 'الرد على الاقتراح البديل',
        bodyEn: `${proposedByName} has ${statusTextEn} your proposed time: ${timeString} for ${serviceName}`,
        bodyAr: `${proposedByName} قام بـ ${statusTextAr} الوقت المقترح: ${timeString} لـ ${serviceNameAr}`,
        data: {
          targetRole: targetRole,
          category: 'counter_offer_response',
          bookingId,
          offerId,
          proposedBy,
          proposedByUid,
          status: newStatus,
          proposedTime: timeString,
          serviceName,
          serviceNameAr,
        },
        fcmToken,
        lanCode,
      });

      console.log(`Counter offer response notification sent to ${targetRole} ${targetId}`);
    } catch (error) {
      console.error('Error sending counter offer response notification:', error);
    }

    return null;
  }
);

// ============================================
// Expire Warranties After 7 Days (Only if Unchanged)
// ============================================
exports.expireUnchangedWarranties = onSchedule(
  {
    schedule: "0 2 * * *", // Runs daily at 2:00 AM Saudi Arabia Time
    timeZone: "Asia/Riyadh",
  },
  async (event) => {
    logger.info("Starting warranty expiry check for unchanged warranties...");

    try {
      // Calculate the date exactly 7 days ago from now
      const sevenDaysAgo = new Date();
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
      sevenDaysAgo.setHours(23, 59, 59, 999); // End of that day

      logger.info(
        `Checking warranties for bookings completed on or before ${sevenDaysAgo.toISOString()}`
      );

      // Query bookings that were completed (status "C") at least 7 days ago
      // and have a warranty with status "A" (available)
      const bookingsSnapshot = await db
        .collection("bookings")
        .where("bookingStatusCode", "==", "C")
        .where("warranty.warrantyStatusCode", "==", "A")
        .get();

      if (bookingsSnapshot.empty) {
        logger.info("No bookings found with available warranties.");
        return null;
      }

      let expiredCount = 0;
      let skippedCount = 0;
      const batch = db.batch();
      const batchSize = 500; // Firestore batch limit

      for (const bookingDoc of bookingsSnapshot.docs) {
        const bookingData = bookingDoc.data();
        const warranty = bookingData.warranty;

        // Skip if no warranty exists
        if (!warranty) {
          skippedCount++;
          continue;
        }

        // Verify warranty status is "A"
        if (warranty.warrantyStatusCode !== "A") {
          skippedCount++;
          continue;
        }

        // Check if warranty has been modified since creation
        // If updatedAt exists and is different from createdAt, skip
        const createdAt = warranty.createdAt;
        const updatedAt = warranty.updatedAt;

        if (updatedAt && createdAt) {
          // Convert to timestamps for comparison
          const createdTimestamp = createdAt.toMillis
            ? createdAt.toMillis()
            : createdAt;
          const updatedTimestamp = updatedAt.toMillis
            ? updatedAt.toMillis()
            : updatedAt;

          // If warranty has been updated (timestamps differ), skip expiration
          if (updatedTimestamp !== createdTimestamp) {
            logger.info(
              `Skipping booking ${bookingDoc.id} - warranty has been modified since creation`
            );
            skippedCount++;
            continue;
          }
        }

        // Check if warranty was created at least 7 days ago
        if (!createdAt) {
          logger.warn(
            `Skipping booking ${bookingDoc.id} - warranty has no createdAt timestamp`
          );
          skippedCount++;
          continue;
        }

        const createdDate = createdAt.toDate
          ? createdAt.toDate()
          : new Date(createdAt);

        // If warranty was created less than 7 days ago, skip
        if (createdDate > sevenDaysAgo) {
          skippedCount++;
          continue;
        }

        const bookingRef = bookingDoc.ref;

        // Update warranty status to Expired (E), set expiredOn and updatedAt
        batch.update(bookingRef, {
          "warranty.warrantyStatusCode": "E",
          "warranty.expiredOn": admin.firestore.FieldValue.serverTimestamp(),
          "warranty.updatedAt": admin.firestore.FieldValue.serverTimestamp(),
        });

        expiredCount++;
        batchCount++;

        logger.info(
          `Scheduled warranty expiration for booking ${bookingDoc.id
          } (created: ${createdDate.toISOString()})`
        );

        // Commit batch every 500 operations
        if (batchCount >= batchSize) {
          await batch.commit();
          logger.info(`Committed batch of ${batchCount} updates`);
          batchCount = 0;
        }
      }

      // Commit remaining updates
      if (batchCount > 0) {
        await batch.commit();
        logger.info(`Committed final batch of ${batchCount} updates`);
      }

      logger.info(
        `Warranty expiry check completed. Warranties expired: ${expiredCount}, skipped: ${skippedCount}`
      );
      return null;
    } catch (error) {
      logger.error("Error expiring unchanged warranties:", error);
      throw error;
    }
  }
);

exports.notifyOnNewChatMessage = onValueCreated(
  "messages/{chatId}/{messageId}",
  async (event) => {
    const chatId = event.params.chatId;
    const messageId = event.params.messageId;
    const messageData = event.data.val();

    if (!messageData) {
      console.log(`[${chatId}] No message data found`);
      return null;
    }

    const senderId = messageData.senderId;
    const senderType = messageData.senderType; // 'technician', 'admin', or 'customer'
    const messageText = messageData.text || "";
    const mediaType = messageData.mediaType;

    console.log(
      `[${chatId}] New message from ${senderType} (${senderId}): ${messageText}`
    );

    try {
      // Get chat details from Realtime Database
      const rtdb = admin.database();
      const chatSnapshot = await rtdb.ref(`chats/${chatId}`).once("value");

      if (!chatSnapshot.exists()) {
        console.log(`[${chatId}] Chat not found`);
        return null;
      }

      const chatData = chatSnapshot.val();
      const participants = chatData.participants || {};

      // Determine receiver ID (the participant who is NOT the sender)
      let receiverId = null;
      let receiverType = null;

      for (const [userId, userType] of Object.entries(participants)) {
        if (userId !== senderId) {
          receiverId = userId;
          receiverType = userType;
          break;
        }
      }

      if (!receiverId) {
        console.log(`[${chatId}] No receiver found`);
        return null;
      }

      console.log(`[${chatId}] Receiver: ${receiverType} (${receiverId})`);

      // Get sender's name from their user/customer document
      let senderName = "Someone";
      try {
        if (senderType === "customer") {
          const senderDoc = await db
            .collection("customers")
            .doc(senderId)
            .get();
          if (senderDoc.exists) {
            const senderData = senderDoc.data();
            senderName = senderData.name || senderData.fullName || "Customer";
          }
        } else {
          // technician or admin
          const senderDoc = await db.collection("users").doc(senderId).get();
          if (senderDoc.exists) {
            const senderData = senderDoc.data();
            senderName = senderData.name || senderData.fullName || "Technician";
          }
        }
      } catch (error) {
        console.error(`[${chatId}] Error fetching sender name:`, error);
      }

      // Fetch booking details to get service name and warranty status
      let serviceName = "Service";
      let isWarranty = "false";
      const bookingId = chatData.bookingId;

      if (bookingId) {
        try {
          const bookingDoc = await db
            .collection("bookings")
            .doc(bookingId)
            .get();
          if (bookingDoc.exists) {
            const bookingData = bookingDoc.data();
            serviceName = bookingData.service?.name || "Service";
            if (bookingData.warranty) {
              isWarranty = "true";
            }
          }
        } catch (e) {
          console.error(`[${chatId}] Error fetching booking details:`, e);
        }
      }

      // Get receiver's FCM token and language preference
      let receiverFcmToken = null;
      let receiverLanCode = "en";

      try {
        if (receiverType === "customer") {
          const receiverDoc = await db
            .collection("customers")
            .doc(receiverId)
            .get();
          if (receiverDoc.exists) {
            const receiverData = receiverDoc.data();
            receiverFcmToken = receiverData.fcmToken;
            receiverLanCode = receiverData.lanCode || "en";
          }
        } else {
          // technician or admin
          const receiverDoc = await db
            .collection("users")
            .doc(receiverId)
            .get();
          if (receiverDoc.exists) {
            const receiverData = receiverDoc.data();
            receiverFcmToken = receiverData.fcmToken;
            receiverLanCode = receiverData.lanCode || "en";
          }
        }
      } catch (error) {
        console.error(`[${chatId}] Error fetching receiver data:`, error);
        return null;
      }

      if (!receiverFcmToken || receiverFcmToken.trim() === "") {
        console.log(`[${chatId}] Receiver has no valid FCM token`);
        return null;
      }

      // If the receiver is actively viewing this chat, skip push notifications.
      const presenceSnapshot = await rtdb
        .ref(`chats/${chatId}/presence/${receiverId}`)
        .once("value");

      if (presenceSnapshot.exists() && presenceSnapshot.val() === true) {
        console.log(
          `[${chatId}] Receiver ${receiverId} is actively viewing chat; skipping push notification.`
        );
        return null;
      }

      // Prepare notification message
      let bodyEn = messageText;
      let bodyAr = messageText;

      // Handle media messages
      if (mediaType === "image") {
        bodyEn = "📷 Photo";
        bodyAr = "📷 صورة";
      } else if (mediaType === "video") {
        bodyEn = "🎥 Video";
        bodyAr = "🎥 فيديو";
      }

      // Truncate long messages
      if (bodyEn.length > 100) {
        bodyEn = bodyEn.substring(0, 97) + "...";
        bodyAr = bodyAr.substring(0, 97) + "...";
      }

      const titleEn = `New message from ${senderName}`;
      const titleAr = `رسالة جديدة من ${senderName}`;

      // Get sender and receiver details for navigation
      let senderPhoto = "";
      let receiverName = "User";
      let receiverPhoto = "";

      try {
        // Get sender photo
        if (senderType === "customer") {
          const senderDoc = await db
            .collection("customers")
            .doc(senderId)
            .get();
          if (senderDoc.exists) {
            senderPhoto = senderDoc.data().photo || "";
          }
        } else {
          const senderDoc = await db.collection("users").doc(senderId).get();
          if (senderDoc.exists) {
            senderPhoto = senderDoc.data().photo || "";
          }
        }

        // Get receiver name and photo
        if (receiverType === "customer") {
          const receiverDoc = await db
            .collection("customers")
            .doc(receiverId)
            .get();
          if (receiverDoc.exists) {
            const receiverData = receiverDoc.data();
            receiverName =
              receiverData.name || receiverData.fullName || "Customer";
            receiverPhoto = receiverData.photo || "";
          }
        } else {
          const receiverDoc = await db
            .collection("users")
            .doc(receiverId)
            .get();
          if (receiverDoc.exists) {
            const receiverData = receiverDoc.data();
            receiverName =
              receiverData.name || receiverData.fullName || "Technician";
            receiverPhoto = receiverData.photo || "";
          }
        }
      } catch (error) {
        console.error(`[${chatId}] Error fetching user details:`, error);
      }

      await sendAndStoreNotification({
        targetRole: receiverType,
        targetId: receiverId,
        titleEn: titleEn,
        titleAr: titleAr,
        bodyEn: bodyEn,
        bodyAr: bodyAr,
        data: {
          type: "chat",
          chatId: chatId,
          senderId: senderId,
          senderType: senderType,
          senderName: senderName,
          messageId: messageId,
          bookingId: bookingId || "",
          targetRole: receiverType,
          serviceName: serviceName,
          isWarranty: isWarranty,
          // Navigation fields for technician/admin app
          // When receiver is technician/admin, participant is the sender (customer)
          // When receiver is customer, this won't be used but we set it anyway
          participantName: senderName,
          participantId: senderId,
          participantPhoto: senderPhoto,
          isAdmin: receiverType === "admin" ? "true" : "false",
          technicianName:
            receiverType !== "customer" ? receiverName : senderName,
          technicianPhoto:
            receiverType !== "customer" ? receiverPhoto : senderPhoto,
          // Navigation fields for customer app
          // When receiver is customer, participant is the sender (technician/admin)
          customerName: receiverType === "customer" ? receiverName : senderName,
          customerPhoto:
            receiverType === "customer" ? receiverPhoto : senderPhoto,
        },
        fcmToken: receiverFcmToken,
        lanCode: receiverLanCode,
      });

      return null;
    } catch (error) {
      console.error(`[${chatId}] Error in notifyOnNewChatMessage:`, error);
      return null;
    }
  }
);
// ============================================
// REWARDS SYSTEM CLOUD FUNCTIONS
// ============================================

// Function 1: Reset Tiers Monthly (1st at 00:00 Saudi Arabia Time)
// Resets all worker tier progress at the start of each month
// ============================================
exports.resetMonthlyTiers = onSchedule(
  {
    schedule: "0 0 1 * *", // 1st of every month at 00:00
    timeZone: "Asia/Riyadh",
  },
  async (event) => {
    logger.info("Starting monthly tier reset...");

    try {
      const usersSnapshot = await db.collection("users").get();
      let totalResets = 0;

      const batch = db.batch();
      let batchCount = 0;
      const batchSize = 500;

      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        const userData = userDoc.data();
        const userRef = db.collection("users").doc(userId);

        // Reset tier and job count at user level
        batch.update(userRef, {
          tier: "Bronze",
          previousMonthTier: userData.tier || "Bronze",
          previousMonthJobs: userData.currentMonthJobs || 0,
          previousMonthRating: userData.rating || 0.0,
          currentMonthJobs: 0,
          lastResetDate: admin.firestore.FieldValue.serverTimestamp(),
        });

        totalResets++;
        batchCount++;

        if (batchCount >= batchSize) {
          await batch.commit();
          logger.info(`Committed batch of ${batchCount} resets`);
          batchCount = 0;
        }
      }

      if (batchCount > 0) {
        await batch.commit();
        logger.info(`Committed final batch of ${batchCount} resets`);
      }

      logger.info(`Monthly tier reset completed. Total resets: ${totalResets}`);
      return null;
    } catch (error) {
      logger.error("Error resetting tiers:", error);
      throw error;
    }
  }
);

// ============================================
// Function 2: Calculate and Apply Monthly Bonuses
// Runs on 1st of month at 01:00 (after reset at 00:00)
// Calculates bonuses for PREVIOUS month and adds them
// Example: January's bonus is calculated and added on February 1st
// ============================================
exports.applyMonthlyBonus = onSchedule(
  {
    schedule: "0 1 1 * *", // 1st of every month at 01:00
    timeZone: "Asia/Riyadh",
  },
  async (event) => {
    const today = new Date();

    // Calculate for PREVIOUS month
    const previousMonth = new Date(today);
    previousMonth.setMonth(previousMonth.getMonth() - 1);

    const previousMonthStr = previousMonth.toLocaleString("en-US", {
      month: "long",
      year: "numeric",
    });

    logger.info(`Calculating bonuses for ${previousMonthStr}...`);

    try {
      const usersSnapshot = await db.collection("users").get();
      let totalBonusesApplied = 0;
      let totalBonusAmount = 0;

      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        const userData = userDoc.data();

        // Check if bonus already applied for this month
        const lastBonusMonth = userData.lastBonusMonth;
        const currentMonthKey = `${today.getFullYear()}-${today.getMonth() + 1
          }`;

        if (lastBonusMonth === currentMonthKey) {
          logger.info(`Bonus already applied for user ${userId}`);
          continue;
        }

        // Use PREVIOUS month's data (stored before reset)
        const jobs = userData.previousMonthJobs || 0;
        const rating = userData.previousMonthRating || 0.0;
        const previousTier = userData.previousMonthTier || "Bronze";

        // Calculate tier and bonus percentage based on previous month performance
        let tier = "Bronze";
        let bonusPercentage = 0;

        if (rating >= 4.8 && jobs >= 60) {
          tier = "Platinum";
          bonusPercentage = 0.15;
        } else if (rating >= 4.5 && jobs >= 40) {
          tier = "Gold";
          bonusPercentage = 0.1;
        } else if (rating >= 4.0 && jobs >= 20) {
          tier = "Silver";
          bonusPercentage = 0.05;
        }

        if (bonusPercentage === 0) {
          logger.info(`User ${userId} in Bronze tier. No bonus.`);
          continue;
        }

        // Calculate earnings from PREVIOUS month
        const firstDayOfPrevMonth = new Date(
          previousMonth.getFullYear(),
          previousMonth.getMonth(),
          1
        );
        const lastDayOfPrevMonth = new Date(
          previousMonth.getFullYear(),
          previousMonth.getMonth() + 1,
          0,
          23,
          59,
          59
        );

        // Query transactions for previous month
        const transactionsSnapshot = await db
          .collection("transactions")
          .where("workerId", "==", userId)
          .where("paymentStatus", "==", "completed")
          .where("createdAt", ">=", firstDayOfPrevMonth.toISOString())
          .where("createdAt", "<=", lastDayOfPrevMonth.toISOString())
          .get();

        // Calculate total earnings from all transactions
        let totalEarnings = 0;
        transactionsSnapshot.forEach((doc) => {
          const transaction = doc.data();
          const amount =
            typeof transaction.amount === "string"
              ? parseFloat(transaction.amount)
              : transaction.amount;
          totalEarnings += amount || 0;
        });

        if (totalEarnings === 0) {
          logger.info(`No earnings for user ${userId} in ${previousMonthStr}`);
          continue;
        }

        const bonusAmount = totalEarnings * bonusPercentage;

        // Get current totalMonthlyBonus
        const currentTotalBonus = userData.totalMonthlyBonus;
        const currentTotalBonusNum =
          typeof currentTotalBonus === "string"
            ? parseFloat(currentTotalBonus) || 0
            : currentTotalBonus || 0;
        const newTotalBonus = currentTotalBonusNum + bonusAmount;

        // Update user's totalMonthlyBonus and bonus info
        await db
          .collection("users")
          .doc(userId)
          .update({
            totalMonthlyBonus: newTotalBonus.toFixed(2),
            bonusAmount: bonusAmount,
            lastBonusDate: admin.firestore.FieldValue.serverTimestamp(),
            lastBonusMonth: currentMonthKey,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

        // Send notification to worker
        const workerFcmToken = userData.fcmToken;
        const workerLanCode = userData.lanCode || "en";

        if (workerFcmToken && workerFcmToken.trim() !== "") {
          await sendAndStoreNotification({
            targetRole: "technician",
            targetId: userId,
            titleEn: "🎉 Monthly Bonus Received!",
            titleAr: "🎉 تم استلام المكافأة الشهرية!",
            bodyEn: `Congratulations! You achieved ${tier} tier in ${previousMonthStr} and earned a bonus of ₹${bonusAmount.toFixed(
              2
            )} (${bonusPercentage * 100}% of ₹${totalEarnings.toFixed(
              2
            )} earnings).`,
            bodyAr: `تهانينا! لقد حققت مستوى ${tier} في ${previousMonthStr} وحصلت على مكافأة قدرها ₹${bonusAmount.toFixed(
              2
            )} (${bonusPercentage * 100}٪ من ₹${totalEarnings.toFixed(
              2
            )} أرباح).`,
            data: {
              category: "bonus",
              tier: tier,
              amount: bonusAmount.toFixed(2),
              bonusPercentage: (bonusPercentage * 100).toString(),
              month: previousMonthStr,
            },
            fcmToken: workerFcmToken,
            lanCode: workerLanCode,
          });
        }

        totalBonusesApplied++;
        totalBonusAmount += bonusAmount;

        logger.info(
          `Applied ${tier} bonus of ₹${bonusAmount.toFixed(
            2
          )} to user ${userId} for ${previousMonthStr} (based on ₹${totalEarnings.toFixed(
            2
          )} earnings)`
        );
      }
      logger.info(
        `Monthly bonus calculation completed for ${previousMonthStr}. Bonuses applied: ${totalBonusesApplied}, Total amount: ₹${totalBonusAmount.toFixed(
          2
        )}`
      );
      return null;
    } catch (error) {
      logger.error("Error calculating bonuses:", error);
      throw error;
    }
  }
);

// ============================================
// Function 3: Update Tier Stats on Job Completion
// Triggers when a booking status changes to completed
// ============================================
exports.updateTierStatsOnJobComplete = onDocumentUpdated(
  "bookings/{jobId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    // Only proceed if status changed to completed
    if (before.bookingStatusCode === "C" || after.bookingStatusCode !== "C") {
      return null;
    }

    const workerId = after.agent?.uid;
    const serviceName = after.service?.name;
    const rating = after.review?.rating || 0;

    if (!workerId) {
      logger.warn(`Booking ${event.params.jobId} missing workerId`);
      return null;
    }

    try {
      const userRef = db.collection("users").doc(workerId);
      const userDoc = await userRef.get();

      if (!userDoc.exists) {
        logger.warn(`User ${workerId} not found`);
        return null;
      }

      const userData = userDoc.data() || {};
      const currentJobs = userData.currentMonthJobs || 0;
      const currentRating = userData.rating || 0;
      const currentTier = userData.tier || "Bronze";

      // Calculate new average rating (overall, not per-category)
      const newJobCount = currentJobs + 1;
      const newAverageRating =
        (currentRating * currentJobs + rating) / newJobCount;

      // Calculate new tier based on total jobs and overall rating
      let newTier = "Bronze";
      if (newAverageRating >= 4.8 && newJobCount >= 60) {
        newTier = "Platinum";
      } else if (newAverageRating >= 4.5 && newJobCount >= 40) {
        newTier = "Gold";
      } else if (newAverageRating >= 4.0 && newJobCount >= 20) {
        newTier = "Silver";
      }

      // Update user document with job count, rating, and tier
      await userRef.update({
        currentMonthJobs: admin.firestore.FieldValue.increment(1),
        rating: newAverageRating,
        tier: newTier,
      });

      // Send notification if tier upgraded
      if (newTier !== currentTier) {
        const tierOrder = { Bronze: 0, Silver: 1, Gold: 2, Platinum: 3 };
        if (tierOrder[newTier] > tierOrder[currentTier]) {
          const fcmToken = userData.fcmToken;
          const lanCode = userData.lanCode || "en";

          if (fcmToken && fcmToken.trim() !== "") {
            const bonusPercentages = {
              Silver: "5%",
              Gold: "10%",
              Platinum: "15%",
            };

            await sendAndStoreNotification({
              targetRole: "technician",
              targetId: workerId,
              titleEn: `🎊 Tier Upgraded to ${newTier}!`,
              titleAr: `🎊 تمت ترقية المستوى إلى ${newTier}!`,
              bodyEn: `Congratulations! You've been upgraded to ${newTier} tier! You now earn ${bonusPercentages[newTier] || "0%"
                } bonus on your monthly earnings. Keep up the great work!`,
              bodyAr: `تهانينا! تمت ترقيتك إلى مستوى ${newTier}! أنت الآن تكسب ${bonusPercentages[newTier] || "0%"
                } مكافأة على أرباحك الشهرية. استمر في العمل الرائع!`,
              data: {
                category: "tier_upgrade",
                oldTier: currentTier,
                newTier: newTier,
                jobs: newJobCount.toString(),
                rating: newAverageRating.toFixed(2),
              },
              fcmToken: fcmToken,
              lanCode: lanCode,
            });

            logger.info(
              `🎊 Tier upgraded for user ${workerId}: ${currentTier} → ${newTier}`
            );
          }
        }
      }

      logger.info(
        `✅ Updated stats for user ${workerId} (${serviceName}): ${newJobCount} jobs, ${newAverageRating.toFixed(
          2
        )} rating, tier: ${newTier}`
      );

      return null;
    } catch (error) {
      logger.error("Error updating tier stats:", error);
      throw error;
    }
  }
);

// ============================================
// Notify Technician on Warranty Assignment
// ============================================
exports.notifyTechnicianOnWarrantyAssignment = onDocumentWritten(
  "bookings/{bookingId}",
  async (event) => {
    const bookingId = event.params.bookingId;
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();

    if (!afterData) {
      console.log(`[${bookingId}] Document deleted, skipping...`);
      return;
    }

    const beforeWarranty = beforeData?.warranty;
    const afterWarranty = afterData?.warranty;

    // Check if warranty exists
    if (!afterWarranty) {
      return;
    }

    // Check warranty status codes
    const beforeStatusCode = beforeWarranty?.warrantyStatusCode;
    const afterStatusCode = afterWarranty.warrantyStatusCode;

    // Check if assignedTechnicianId changed
    const beforeTechnicianId = beforeWarranty?.assignedTechnicianId;
    const afterTechnicianId = afterWarranty.assignedTechnicianId;

    // Only trigger notification when:
    // 1. assignedTechnicianId changes from null/undefined to a technician UID
    // 2. AND warranty status changes from "R" (requested) to "S" (started/assigned)
    // This prevents false triggers when warranty is created with status "A" after payment

    // Skip if no technician assigned now
    if (!afterTechnicianId) {
      return;
    }

    // Skip if technician didn't change
    if (beforeTechnicianId === afterTechnicianId) {
      return;
    }

    // Skip if there was already a technician assigned before (should be null/undefined)
    if (beforeTechnicianId != null) {
      console.log(
        `[${bookingId}] Skipping warranty notification - technician reassignment (was ${beforeTechnicianId}, now ${afterTechnicianId})`
      );
      return;
    }

    // Skip if status didn't change from R to S
    if (beforeStatusCode !== "R" || afterStatusCode !== "S") {
      console.log(
        `[${bookingId}] Skipping warranty notification - status not R→S (was ${beforeStatusCode}, now ${afterStatusCode})`
      );
      return;
    }

    console.log(
      `[${bookingId}] 🔔 Warranty technician assignment detected: Admin assigned technician ${afterTechnicianId} (status R→S)`
    );

    // Fetch technician data
    try {
      const technicianDoc = await admin
        .firestore()
        .collection("users")
        .doc(afterTechnicianId)
        .get();

      if (!technicianDoc.exists) {
        console.log(
          `[${bookingId}] Technician document not found for ID: ${afterTechnicianId}`
        );
        return;
      }

      const technicianData = technicianDoc.data();
      const technicianFcmToken = technicianData?.fcmToken;
      const technicianLanCode = technicianData?.lanCode || "en";

      if (!technicianFcmToken || technicianFcmToken.trim() === "") {
        console.log(
          `[${bookingId}] Technician ${afterTechnicianId} has no valid FCM token`
        );
        return;
      }

      // Get booking details
      const serviceName = afterData.service?.name || "Service";
      const serviceNameAr = afterData.service?.name_ar || serviceName;
      const customerName = afterData.customer?.name || "Customer";
      const customerId = afterData.customer?.uid || "";

      // Send notification
      await sendAndStoreNotification({
        targetRole: "technician",
        targetId: afterTechnicianId,
        titleEn: "Warranty Repair Assigned",
        titleAr: "تم تعيينك لإصلاح ضمان",
        bodyEn: `You have been assigned to a warranty repair for ${serviceName}. Customer: ${customerName}. Please review and accept.`,
        bodyAr: `تم تعيينك لإصلاح ضمان لـ ${serviceNameAr}. العميل: ${customerName}. يرجى المراجعة والقبول.`,
        data: {
          targetRole: "technician",
          category: "warranty",
          bookingId: bookingId,
          customerId: customerId,
          customerName: customerName,
          warrantyStatusCode: afterWarranty.warrantyStatusCode || "",
          serviceName: serviceName,
          isWarranty: "true",
          isAdmin: "false",
        },
        fcmToken: technicianFcmToken,
        lanCode: technicianLanCode,
      });

      console.log(
        `[${bookingId}] ✅ Warranty assignment notification sent to technician ${afterTechnicianId}`
      );
    } catch (error) {
      console.error(
        `[${bookingId}] Error sending warranty assignment notification:`,
        error
      );
    }

    return null;
  }
);

// ============================================
// Notify Admins on New Payout Request
// ============================================

exports.notifyAdminsOnPayoutRequest = onDocumentCreated(
  "payouts/{payoutId}",
  async (event) => {
    const payoutId = event.params.payoutId;
    const payoutData = event.data?.data();

    if (!payoutData) {
      console.log(`[${payoutId}] No payout data found`);
      return;
    }

    const userId = payoutData.userId;
    const amount = payoutData.amount || "0";
    const type = payoutData.type || "earnings"; // earnings, bonus,
    const status = payoutData.status;

    // Only notify on pending requests
    if (status !== "P") {
      console.log(`[${payoutId}] Payout status is not pending, skipping...`);
      return;
    }

    console.log(
      `[${payoutId}] New ${type} payout request detected for user ${userId}, amount: ${amount}`
    );

    // Fetch technician data
    let technicianData;
    try {
      const technicianDoc = await admin
        .firestore()
        .collection("users")
        .doc(userId)
        .get();

      if (!technicianDoc.exists) {
        console.log(`[${payoutId}] Technician document not found`);
        return;
      }

      technicianData = technicianDoc.data();
    } catch (error) {
      console.error(`[${payoutId}] Error fetching technician data:`, error);
      return;
    }

    const technicianName = technicianData?.name || "Technician";

    // Determine notification content based on payout type
    let titleEn, titleAr, bodyEn, bodyAr;

    switch (type) {
      case "earnings":
        titleEn = "New Earnings Payout Request";
        titleAr = "طلب صرف أرباح جديد";
        bodyEn = `${technicianName} has requested an earnings payout of ${amount}.`;
        bodyAr = `طلب ${technicianName} صرف أرباح بقيمة ${amount}.`;
        break;
      case "bonus":
        titleEn = "New Bonus Payout Request";
        titleAr = "طلب صرف مكافأة جديد";
        bodyEn = `${technicianName} has requested a bonus payout of ${amount}.`;
        bodyAr = `طلب ${technicianName} صرف مكافأة بقيمة ${amount}.`;
        break;
      default:
        titleEn = "New Payout Request";
        titleAr = "طلب صرف جديد";
        bodyEn = `${technicianName} has requested a payout of ${amount}.`;
        bodyAr = `طلب ${technicianName} صرف بقيمة ${amount}.`;
    }

    // Fetch all admin users
    try {
      const adminUsersDocs = await getAllAdminUsers();

      if (adminSnapshot.empty) {
        console.log(`[${payoutId}] No admin users found`);
        return;
      }

      // Send notification to each admin
      for (const adminDoc of adminSnapshot.docs) {
        const adminData = adminDoc.data();
        const adminFcmToken = adminData?.fcmToken;
        const adminLanCode = adminData?.lanCode || "en";

        if (!adminFcmToken || adminFcmToken.trim() === "") {
          console.log(
            `[${payoutId}] Admin ${adminDoc.id} has no valid FCM token`
          );
          continue;
        }

        await sendAndStoreNotification({
          targetRole: "admin",
          targetId: adminDoc.id,
          titleEn,
          titleAr,
          bodyEn,
          bodyAr,
          data: {
            targetRole: "admin",
            category: "payout",
            payoutId,
            userId,
            technicianName,
            amount,
            type,
            isAdmin: "true",
          },
          fcmToken: adminFcmToken,
          lanCode: adminLanCode,
        });
      }

      console.log(
        `[${payoutId}] ✅ Payout request notifications sent to admins`
      );
    } catch (error) {
      console.error(
        `[${payoutId}] Error sending payout request notifications:`,
        error
      );
    }

    return null;
  }
);

// ============================================
// Notify Admins on Tip Payout Request
// ============================================

exports.notifyAdminsOnTipPayoutRequest = onDocumentWritten(
  "tipping/{agentId}",
  async (event) => {
    const agentId = event.params.agentId;
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();

    if (!afterData) {
      console.log(`[${agentId}] Document deleted, skipping...`);
      return;
    }

    const wasPayoutRequested = beforeData?.payoutRequested || false;
    const isPayoutRequested = afterData.payoutRequested || false;

    // Only notify when payoutRequested changes from false to true
    if (!isPayoutRequested || wasPayoutRequested) {
      return;
    }

    const technicianName = afterData.agentName || "Technician";
    const cardTips = afterData.cardtip || 0;

    console.log(
      `[${agentId}] Tip payout request detected for ${technicianName}, amount: ${cardTips}`
    );

    // Fetch all admin users
    try {
      const adminUsersDocs = await getAllAdminUsers();

      if (adminSnapshot.empty) {
        console.log(`[${agentId}] No admin users found`);
        return;
      }

      // Send notification to each admin
      for (const adminDoc of adminSnapshot.docs) {
        const adminData = adminDoc.data();
        const adminFcmToken = adminData?.fcmToken;
        const adminLanCode = adminData?.lanCode || "en";

        if (!adminFcmToken || adminFcmToken.trim() === "") {
          console.log(
            `[${agentId}] Admin ${adminDoc.id} has no valid FCM token`
          );
          continue;
        }

        await sendAndStoreNotification({
          targetRole: "admin",
          targetId: adminDoc.id,
          titleEn: "New Tips Payout Request",
          titleAr: "طلب صرف إكراميات جديد",
          bodyEn: `${technicianName} has requested a tips payout of ${cardTips}.`,
          bodyAr: `طلب ${technicianName} صرف إكراميات بقيمة ${cardTips}.`,
          data: {
            targetRole: "admin",
            category: "tips_payout",
            agentId,
            technicianName,
            amount: cardTips.toString(),
            type: "tips",
            isAdmin: "true",
          },
          fcmToken: adminFcmToken,
          lanCode: adminLanCode,
        });
      }

      console.log(
        `[${agentId}] ✅ Tip payout request notifications sent to admins`
      );
    } catch (error) {
      console.error(
        `[${agentId}] Error sending tip payout request notifications:`,
        error
      );
    }

    return null;
  }
);

// ============================================
// Notify Technician on Tip Payout Completion
// ============================================
exports.notifyTechnicianOnTipPayoutCompletion = onDocumentWritten(
  "tipping/{agentId}",
  async (event) => {
    const agentId = event.params.agentId;
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();

    if (!afterData) {
      console.log(`[${agentId}] Document deleted, skipping...`);
      return;
    }

    const beforeCardTip = beforeData?.cardtip || 0;
    const afterCardTip = afterData.cardtip || 0;
    const beforePayoutRequested = beforeData?.payoutRequested || false;
    const afterPayoutRequested = afterData.payoutRequested || false;

    // Notify when cardtip is cleared (goes to 0) and payoutRequested changes from true to false
    // This indicates admin has processed the tip payout
    if (
      beforePayoutRequested &&
      !afterPayoutRequested &&
      beforeCardTip > 0 &&
      afterCardTip === 0
    ) {
      console.log(
        `[${agentId}] Tip payout completed, amount cleared: ${beforeCardTip}`
      );

      // Fetch technician data
      let technicianData;
      try {
        const technicianDoc = await admin
          .firestore()
          .collection("users")
          .doc(agentId)
          .get();

        if (!technicianDoc.exists) {
          console.log(`[${agentId}] Technician document not found`);
          return;
        }

        technicianData = technicianDoc.data();
      } catch (error) {
        console.error(`[${agentId}] Error fetching technician data:`, error);
        return;
      }

      const technicianFcmToken = technicianData?.fcmToken;
      const technicianLanCode = technicianData?.lanCode || "en";

      if (!technicianFcmToken || technicianFcmToken.trim() === "") {
        console.log(`[${agentId}] Technician has no valid FCM token`);
        return;
      }

      // Send notification to technician
      try {
        await sendAndStoreNotification({
          targetRole: "technician",
          targetId: agentId,
          titleEn: "Tips Payout Completed",
          titleAr: "تم صرف الإكراميات",
          bodyEn: `Your tips payout of ${beforeCardTip} has been processed and sent to your account.`,
          bodyAr: `تم معالجة صرف إكراميات ك بقيمة ${beforeCardTip} وإرسالها إلى حسابك.`,
          data: {
            targetRole: "technician",
            category: "tips_payout",
            amount: beforeCardTip.toString(),
            type: "tips",
            status: "completed",
            isAdmin: "false",
          },
          fcmToken: technicianFcmToken,
          lanCode: technicianLanCode,
        });

        console.log(
          `[${agentId}] ✅ Tip payout completion notification sent to technician`
        );
      } catch (error) {
        console.error(
          `[${agentId}] Error sending tip payout completion notification:`,
          error
        );
      }
    }

    return null;
  }
);
// ============================================
// Notify Technician on Payout Approval/Rejection
// ============================================
exports.notifyTechnicianOnPayoutStatusChange = onDocumentWritten(
  "payouts/{payoutId}",
  async (event) => {
    const payoutId = event.params.payoutId;
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();

    if (!afterData) {
      console.log(`[${payoutId}] Document deleted, skipping...`);
      return;
    }

    const beforeStatus = beforeData?.status;
    const afterStatus = afterData.status;

    // Check if status changed to approved (C) or rejected (R)
    if (beforeStatus === afterStatus) {
      console.log(`[${payoutId}] No status change detected, skipping...`);
      return;
    }

    // Only notify on approval or rejection
    if (afterStatus !== "C" && afterStatus !== "R") {
      console.log(
        `[${payoutId}] Status is not approved or rejected, skipping...`
      );
      return;
    }

    const userId = afterData.userId;
    const amount = afterData.amount || "0";
    const type = afterData.type || "earnings";
    const transactionNumber = afterData.transactionNumber || "";
    const rejectionReason = afterData.rejectionReason || "";

    console.log(
      `[${payoutId}] Payout status changed to ${afterStatus} for user ${userId}`
    );

    // Fetch technician data
    let technicianData;
    try {
      const technicianDoc = await admin
        .firestore()
        .collection("users")
        .doc(userId)
        .get();

      if (!technicianDoc.exists) {
        console.log(`[${payoutId}] Technician document not found`);
        return;
      }

      technicianData = technicianDoc.data();
    } catch (error) {
      console.error(`[${payoutId}] Error fetching technician data:`, error);
      return;
    }

    const technicianFcmToken = technicianData?.fcmToken;
    const technicianLanCode = technicianData?.lanCode || "en";

    if (!technicianFcmToken || technicianFcmToken.trim() === "") {
      console.log(`[${payoutId}] Technician has no valid FCM token`);
      return;
    }

    // Determine notification content based on status and type
    let titleEn, titleAr, bodyEn, bodyAr;

    // Get type-specific labels
    const typeLabels = {
      earnings: { en: "earnings", ar: "الأرباح" },
      bonus: { en: "bonus", ar: "المكافأة" },
      tips: { en: "tips", ar: "الإكراميات" },
    };

    const typeLabel = typeLabels[type] || typeLabels.earnings;

    if (afterStatus === "C") {
      // Approved
      titleEn = "Payout Request Approved";
      titleAr = "تمت الموافقة على طلب الصرف";
      bodyEn = `Your ${typeLabel.en} payout request of ${amount} has been approved. Transaction number: ${transactionNumber}`;
      bodyAr = `تمت الموافقة على طلب صرف ${typeLabel.ar} الخاص بك بقيمة ${amount}. رقم المعاملة: ${transactionNumber}`;
    } else if (afterStatus === "R") {
      // Rejected
      titleEn = "Payout Request Rejected";
      titleAr = "تم رفض طلب الصرف";
      bodyEn = `Your ${typeLabel.en
        } payout request of ${amount} has been rejected.${rejectionReason ? ` Reason: ${rejectionReason}` : ""
        }`;
      bodyAr = `تم رفض طلب صرف ${typeLabel.ar} الخاص بك بقيمة ${amount}.${rejectionReason ? ` السبب: ${rejectionReason}` : ""
        }`;
    }

    // Send notification to technician
    try {
      await sendAndStoreNotification({
        targetRole: "technician",
        targetId: userId,
        titleEn,
        titleAr,
        bodyEn,
        bodyAr,
        data: {
          targetRole: "technician",
          category: "payout",
          payoutId,
          amount,
          type,
          status: afterStatus,
          transactionNumber: transactionNumber || "",
          rejectionReason: rejectionReason || "",
          isAdmin: "false",
        },
        fcmToken: technicianFcmToken,
        lanCode: technicianLanCode,
      });

      console.log(
        `[${payoutId}] ✅ Payout ${afterStatus === "C" ? "approval" : "rejection"
        } notification sent to technician ${userId}`
      );
    } catch (error) {
      console.error(
        `[${payoutId}] Error sending payout status notification:`,
        error
      );
    }

    return null;
  }
);

// Scheduled function to expire warranties after 7 days
exports.expireWarrantiesDaily = onSchedule(
  {
    schedule: "every day 00:00",
    timeZone: "Asia/Riyadh",
  },
  async (event) => {
    console.log("🕐 Starting daily warranty expiry check...");

    try {
      // Get all completed bookings with available warranties
      const bookingsSnapshot = await db
        .collection("bookings")
        .where("bookingStatusCode", "==", "C")
        .where("warranty.warrantyStatusCode", "==", "A")
        .get();

      console.log(
        `📊 Found ${bookingsSnapshot.size} bookings with available warranties`
      );

      const now = admin.firestore.Timestamp.now();
      const sevenDaysInMs = 7 * 24 * 60 * 60 * 1000; // Exactly 7 days in milliseconds
      let expiredCount = 0;

      const batch = db.batch();

      for (const doc of bookingsSnapshot.docs) {
        const booking = doc.data();
        const warranty = booking.warranty;

        // Skip if warranty doesn't exist or is missing required fields
        if (!warranty || !booking.completedAt || !warranty.createdAt) {
          continue;
        }

        // Check if warranty has been modified (updatedAt !== createdAt)
        // If updatedAt doesn't exist, treat it as not modified
        const hasBeenModified =
          warranty.updatedAt &&
          warranty.updatedAt.toMillis() !== warranty.createdAt.toMillis();

        if (hasBeenModified) {
          console.log(
            `⏭️  Skipping booking ${doc.id} - warranty has been modified`
          );
          continue;
        }

        // Calculate days since service completion
        const completedAtMs = booking.completedAt.toMillis();
        const daysSinceCompletion =
          (now.toMillis() - completedAtMs) / (24 * 60 * 60 * 1000);

        console.log(
          `📅 Booking ${doc.id}: ${daysSinceCompletion.toFixed(
            2
          )} days since completion`
        );

        // Expire if exactly 7 or more days have passed
        if (daysSinceCompletion >= 7) {
          console.log(
            `⏰ Expiring warranty for booking ${doc.id
            } (${daysSinceCompletion.toFixed(2)} days old)`
          );

          batch.update(doc.ref, {
            "warranty.warrantyStatusCode": "E",
            "warranty.expiredOn": now,
            "warranty.updatedAt": FieldValue.serverTimestamp(),
          });

          expiredCount++;
        }
      }

      if (expiredCount > 0) {
        await batch.commit();
        console.log(`✅ Expired ${expiredCount} warranties`);
      } else {
        console.log("ℹ️  No warranties to expire");
      }

      return null;
    } catch (error) {
      console.error("❌ Error expiring warranties:", error);
      throw error;
    }
  }
);
