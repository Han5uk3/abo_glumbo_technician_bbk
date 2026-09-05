const {
  onDocumentCreated,
  onDocumentWritten,
} = require("firebase-functions/v2/firestore");
const { onRequest } = require("firebase-functions/v2/https");
const { onDocumentUpdated, onDocumentDeleted } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onValueCreated } = require("firebase-functions/v2/database");
const { logger } = require("firebase-functions/v2");
const admin = require("firebase-admin");
const DATABASE_URL = "https://worker-app-tnext-default-rtdb.firebaseio.com";
admin.initializeApp({
  databaseURL: DATABASE_URL,
});
const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

// `admin.database` is the namespace accessor: its argument is an App, never a
// URL. `admin.database(someUrl)` compiles, deploys, and then throws
// "this.ensureApp(...).database is not a function" on the first line of every
// invocation - which the callers' own try/catch swallowed into a logged error
// and a `return null`, so every chat push was lost, for both apps, with the
// cause visible only in the function logs. The URL belongs to App.database().
const getRtdb = () => admin.app().database(DATABASE_URL);

// A chat's `participants` map is keyed by ROLE, not by uid.
//
// Both apps sign in against this one Firebase project with phone auth, so a
// uid identifies a person and not a person-in-a-role: someone who is both a
// customer and a technician has exactly ONE uid. The old uid -> role map
// collapsed those two entries into one, and the receiver lookup - "the
// participant who is not the sender" - then found nobody. A chat has exactly
// one participant per role, so role is a key that cannot collide.
const CHAT_ROLES = ["customer", "technician", "admin"];

/** The uid holding `role`, accepting the role -> uid map or the legacy uid -> role one. */
function participantUid(participants, role) {
  const direct = participants[role];
  if (typeof direct === "string" && direct) return direct;
  for (const [key, value] of Object.entries(participants)) {
    if (value === role && !CHAT_ROLES.includes(key)) return key;
  }
  return null;
}

/** Every uid named in a `participants` map, in either shape. */
function participantUids(participants) {
  const uids = new Set();
  for (const [key, value] of Object.entries(participants || {})) {
    if (CHAT_ROLES.includes(key)) {
      if (typeof value === "string" && value) uids.add(value);
    } else if (key) {
      uids.add(key);
    }
  }
  return [...uids];
}
// Every Firestore trigger is pinned to a region collocated with the eur3
// database. These used to be unpinned, which let the CLI place newly created
// functions in europe-west1 while older ones stayed in us-central1 - identical
// source, different regions, and a transatlantic hop on every event.
const FUNCTION_REGION = "europe-west1";


// Single implementation, shared with src/triggers/bookingTriggers.js. This file
// used to carry its own copy; the two drifted into writing different field
// names and building different FCM payloads, so there is only one now.
// Required after initializeApp() because bookingUtils calls admin.firestore()
// at module load.
const {
  sendAndStoreNotification,
  toNotificationRecipients,
  money,
} = require("./src/utils/bookingUtils");



// Helper function to get all admin users (main admins + granted admins)
// Excludes customer service admins (adminAccessLevel == 2)
async function getAllAdminUsers() {
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

exports.notifyAdminsOnNewBooking = onDocumentCreated(
  { document: "bookings/{bookingId}", region: FUNCTION_REGION },
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
    const serviceNameUr = booking.service?.name_ur || serviceNameAr || serviceName;

    try {
      const adminUsersDocs = await getAllAdminUsers();

      const tokensWithLanguage = toNotificationRecipients(adminUsersDocs);

      if (tokensWithLanguage.length === 0) {
        console.log("No admins found.");
        return null;
      }

      const results = [];

      for (const { uid, token, lanCode } of tokensWithLanguage) {
        await sendAndStoreNotification({
          targetRole: "admin",
          targetId: uid,
          titleEn: `New Booking Request: ${serviceName}`,
          titleAr: `طلب حجز جديد: ${serviceNameAr}`,
          titleUr: `بکنگ کی نئی درخواست: ${serviceNameUr}`,
          bodyEn: `A new booking for ${serviceName} is pending approval.`,
          bodyAr: `هناك حجز جديد لـ ${serviceNameAr} بانتظار الموافقة.`,
          bodyUr: `${serviceNameUr} کے لیے ایک نئی بکنگ منظوری کا انتظار کر رہی ہے۔`,
          data: {
            targetRole: "admin",
            category: "booking",
            bookingId: event.params.bookingId,
            serviceName: serviceName,
            serviceNameAr: serviceNameAr,
            serviceNameUr: serviceNameUr,
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
  { document: "bookings/{bookingId}", region: FUNCTION_REGION },
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
    const serviceNameUr = afterData?.service?.name_ur || serviceNameAr || serviceName;

    // --- Fetch admin users once ---
    let adminTokens = [];
    try {
      const adminUsersDocs = await getAllAdminUsers();

      adminTokens = toNotificationRecipients(adminUsersDocs);

      if (adminTokens.length === 0) {
        console.log(`[${bookingId}] No admins found`);
      }
    } catch (error) {
      console.error(`[${bookingId}] Error fetching admin users:`, error);
    }

    // ==============================
    // 1. New Assignment Notification
    // ==============================
    const statusChangedToAssigned =
      (beforeData?.bookingStatusCode !== "A" && afterData.bookingStatusCode === "A") ||
      (afterData.bookingStatusCode === "A" && beforeData?.agent?.uid !== afterData?.agent?.uid && afterData?.agent?.uid);

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
              titleUr: `نیا بکنگ تفویض کیا گیا: ${serviceNameUr}`,
              bodyEn: "You have been assigned to a booking.",
              bodyAr: "لقد تم تعيينك في حجز جديد.",
              bodyUr: "آپ کو ایک بکنگ تفویض کی گئی ہے۔",
              data: {
                targetRole: "technician",
                category: "booking",
                bookingId,
                serviceName,
                serviceNameAr: serviceNameAr,
                serviceNameUr: serviceNameUr,
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
        await Promise.allSettled(adminTokens.map(async ({ uid, token, lanCode }) => {
          await sendAndStoreNotification({
            targetRole: "admin",
            targetId: uid,
            titleEn: `New Agent Assigned: ${serviceName}`,
            titleAr: `تم تعيين فني جديد: ${serviceNameAr}`,
            titleUr: `ٹیکنیشن تفویض کر دیا گیا: ${serviceNameUr}`,
            bodyEn: `A technician has been assigned to a new booking for "${serviceName}".`,
            bodyAr: `تم تعيين فني لحجز جديد لخدمة "${serviceNameAr}".`,
            bodyUr: `سروس "${serviceNameUr}" کے لیے ایک ٹیکنیشن تفویض کر دیا گیا ہے۔`,
            data: {
              targetRole: "admin",
              category: "booking",
              bookingId,
              serviceName,
              serviceNameAr: serviceNameAr,
              serviceNameUr: serviceNameUr,
              isAdmin: "true",
            },
            fcmToken: token,
            lanCode: lanCode,
          });
        }));
      }
    }



    return null;
  }
);
exports.notifyCustomerOnBookingStatusChange = onDocumentWritten(
  { document: "bookings/{bookingId}", region: FUNCTION_REGION },
  async (event) => {
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();

    if (!afterData) {
      console.log("Document deleted, skipping...");
      return;
    }

    if (afterData.bookingStatusCode === "P") {
      console.log("Booking status is pending/searching, skipping notification...");
      return;
    }

    // Check for status change or payment completion change
    const statusChanged =
      beforeData?.bookingStatusCode !== afterData.bookingStatusCode;
    const paymentCompleted =
      beforeData?.paymentCompleted !== afterData.paymentCompleted;
    const technicianChanged =
      beforeData?.agent?.uid !== afterData?.agent?.uid && afterData?.agent?.uid;

    if (!statusChanged && !paymentCompleted && !technicianChanged) {
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
      const customerDoc = await admin.firestore().collection("customers").doc(customerId).get();
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

    // No early return on a missing token. `sendAndStoreNotification` writes the
    // customers/{uid}/notifications document first and only then pushes, so
    // bailing out here cost the customer the in-app record as well - which is
    // why an unregistered device showed an empty notifications page rather than
    // just missing pushes. See the same note at every other token check below.
    if (!fcmToken || fcmToken.trim() === "") {
      console.log(
        `Customer ${customerId} has no valid FCM token; storing notification without a push.`
      );
    }

    const service = afterData.service;
    const serviceName = service?.name || "Service";
    const serviceNameAr = service?.name_ar || serviceName;
    const serviceNameUr = service?.name_ur || serviceNameAr || serviceName;
    const bookingStatus = afterData.bookingStatusCode;
    const isPaymentCompleted = afterData.paymentCompleted;

    const agentNameEn = afterData.agent?.name || "a technician";
    const agentNameAr = afterData.agent?.name || "فني";
    const agentNameUr = afterData.agent?.name || "ٹیکنیشن";

    const statusMessages = {
      A: {
        en: `Technician ${agentNameEn} has been booked successfully.`,
        ar: `تم حجز الفني ${agentNameAr} بنجاح.`,
        ur: `ٹیکنیشن ${agentNameUr} کو کامیابی کے ساتھ بک کر لیا گیا ہے۔`,
      },
      R: {
        en: "Your booking has been rejected.",
        ar: "تم رفض حجزك.",
        ur: "آپ کی بکنگ مسترد کر دی گئی ہے۔",
      },
      CP: {
        en: "Your service is complete! Payment is pending.",
        ar: "خدمتك مكتملة! الدفع معلق.",
        ur: "آپ کی سروس مکمل ہو گئی ہے! ادائیگی التواء میں ہے۔",
      },
      VP: {
        en: "Your payment verification is pending.",
        ar: "التحقق من الدفع الخاص بك معلق.",
        ur: "آپ کی ادائیگی کی تصدیق التواء میں ہے۔",
      },
      C: {
        // Service complete
        en: "Your service is complete!\nWe hope you had a great experience.",
        ar: "تم الانتهاء من خدمتك!\nنأمل أن تكون قد قضيت وقتًا رائعًا.",
        ur: "آپ کی سروس مکمل ہو گئی ہے!\nہم امید کرتے ہیں کہ آپ کا تجربہ بہترین رہا۔",
      },
      C_PAYMENT_COMPLETED: {
        // Service complete and payment received
        en: "Thank you! Your payment has been received.\nWe'd love to hear about your experience.\nPlease share your feedback by rating your service provider.\nYour reviews help us maintain the best service quality.\nIf you'd like, you can also leave a tip to show your appreciation.",
        ar: "شكراً لك! تم استلام دفعتك.\nنود أن نسمع عن تجربتك.\nيرجى مشاركة آرائك بتقييم مقدم الخدمة الخاص بك.\nتساعدنا تقييماتك في الحفاظ على أفضل جودة للخدمة.\nوإذا رغبت، يمكنك ترك إكرامية.",
        ur: "شکریہ! آپ کی ادائیگی موصول ہو گئی ہے۔\nہمیں آپ کے تجربے کے بارے میں جان کر خوشی ہوگی۔\nبراہ کرم درجہ بندی دے کر اپنی رائے کا اظہار کریں۔\nآپ کے جائزے بہترین سروس کے معیار کو برقرار رکھنے میں ہماری مدد کرتے ہیں۔\nاگر آپ چاہیں تو، آپ تعریفی رقم بھی چھوڑ سکتے ہیں۔",
      },
      XC: {
        en: "Your booking has been canceled.",
        ar: "تم إلغاء حجزك.",
        ur: "آپ کی بکنگ منسوخ کر دی گئی ہے۔",
      },
      REASSIGNED: {
        en: `New technician ${agentNameEn} has been assigned to your booking.`,
        ar: `تم تعيين فني جديد ${agentNameAr} لحجزك.`,
        ur: `آپ کی بکنگ کے لیے نیا ٹیکنیشن ${agentNameUr} تفویض کیا گیا ہے۔`,
      },
    };

    // Determine which message to use
    let messageKey = bookingStatus;
    if (bookingStatus === "C") {
      if (!isPaymentCompleted) {
        messageKey = "CP";
      } else if (afterData.completionData?.mode !== 0) {
        messageKey = "C_PAYMENT_COMPLETED";
      }
    } else if (technicianChanged && !statusChanged && bookingStatus === "A") {
      messageKey = "REASSIGNED";
    }

    const bodyEn =
      statusMessages[messageKey]?.["en"] ||
      `Your booking status changed to ${bookingStatus}`;
    const bodyAr =
      statusMessages[messageKey]?.["ar"] ||
      `تغيرت حالة حجزك إلى ${bookingStatus}`;
    const bodyUr =
      statusMessages[messageKey]?.["ur"] ||
      `آپ کی بکنگ کی صورتحال تبدیل ہو گئی ہے: ${bookingStatus}`;

    await sendAndStoreNotification({
      targetRole: "customer",
      targetId: customerId,
      titleEn: "Booking Status Update",
      titleAr: "تحديث حالة الحجز",
      titleUr: "بکنگ کی صورتحال کا اپ ڈیٹ",
      bodyEn: `${bodyEn} (${serviceName})`,
      bodyAr: `${bodyAr} (${serviceNameAr})`,
      bodyUr: `${bodyUr} (${serviceNameUr})`,
      data: {
        customerId: customerId,
        targetRole: "customer",
        bookingId: event.params.bookingId,
        status: bookingStatus,
        serviceName: serviceName,
        serviceNameAr: serviceNameAr,
        serviceNameUr: serviceNameUr,
        paymentCompleted: isPaymentCompleted.toString(),
        requestId: `${event.params.bookingId}_${messageKey}`,
      },
      fcmToken: fcmToken,
      lanCode: lanCode,
    });
  }
);
/**
 * `paymentModeCode` values that mean the customer paid inside the app (Telr /
 * Apple Pay). Anything else — notably "O" — is an outside-app (cash) payment.
 */
const IN_APP_PAYMENT_CODES = ['c', 'a', 'C', 'A', 'Inside App', 'inside app', 'in app'];

/**
 * Credits a completed booking to the technician's unified wallet.
 *
 * This is the **single writer** of booking earnings. It replaces three separate
 * client-side credits that each only covered part of the matrix:
 *
 *  - the customer app credited in-app earnings on the payment screen,
 *  - the technician app credited outside-app earnings from the verify-payment
 *    sheet, using the `BookingModel` it had loaded — which is stale whenever the
 *    booking was completed after that screen's list was built, in which case
 *    `completionData` was null locally and the credit was silently skipped,
 *  - and `notifyTechnicianOnPaymentCompletion` credited in-app earnings again,
 *    double-counting against the first one, but only if it got that far (it
 *    returns early for warranty claims and when the agent lookup fails).
 *
 * Doing it here instead makes the credit independent of which of the three
 * booking creation paths produced the booking (broadcast, auto-assign, rebook)
 * and of which client happened to observe the payment. It is keyed on the
 * booking's *state* rather than on a field transition, so a booking that reaches
 * a payable state by any route is picked up, and it is made exactly-once by the
 * `walletCreditedAt` marker written on the booking inside the same transaction.
 */
exports.creditTechnicianWalletOnPaymentCompletion = onDocumentWritten(
  { document: "bookings/{bookingId}", region: FUNCTION_REGION },
  async (event) => {
    const bookingId = event.params.bookingId;
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();

    if (!afterData) return; // deleted
    if (afterData.walletCreditedAt) return; // already credited — cheap pre-check

    // Fire on the booking *entering* the payable state — payment settled and the
    // job closed out — rather than on it merely being in that state.
    //
    // Two reasons this is a transition and not a state check. Bookings settled
    // before this function existed were credited by the old client-side paths and
    // carry no `walletCreditedAt` marker, so a state check would back-credit every
    // one of them the next time anything touched the document (a warranty claim,
    // a review, an invoice url). And this trigger fires on every write to the
    // booking, including the marker write below.
    //
    // Comparing the whole payable condition rather than a single field keeps it
    // robust: if a path ever set `paymentCompleted` while still at VP and moved to
    // C afterwards, the second write is the entering transition and still counts.
    const wasPayable =
      beforeData?.paymentCompleted === true &&
      beforeData?.bookingStatusCode === "C";
    const isPayable =
      afterData.paymentCompleted === true && afterData.bookingStatusCode === "C";

    if (!isPayable || wasPayable) return;

    const agentUid = afterData.agent?.uid;
    if (!agentUid) {
      console.log(`[${bookingId}] No agent on booking, nothing to credit`);
      return;
    }

    // Warranty repairs need no explicit exclusion here: `CompleteWarranty` only
    // ever writes `warranty.*` fields, never touching `bookingStatusCode` or
    // `paymentCompleted` on the booking itself (both are already 'C'/true from
    // the original job), so that write is never an entering transition and
    // `wasPayable` above is already true — this trigger returns before
    // reaching this line for that case.
    //
    // The credited amount must match what the customer was actually charged
    // (`sheets/payment.dart`'s `finalAmount` on the customer app, and the
    // outside-app payment proof's prefilled amount): full-service completions
    // (mode 1) charge totalCost + the discounted inspection fee; inspection-
    // only completions (mode 0) charge the discounted inspection fee alone.
    // This mirrors `notifyTechnicianOnPaymentCompletion`'s `totalAmount`
    // exactly, so the push notification and the wallet credit never disagree.
    const discountPercentage = afterData.service?.discountPercentage || 0;
    const baseInspectionFee = Number(afterData.completionData?.inspectionFee) || 0;
    const effectiveInspectionFee = discountPercentage > 0
      ? baseInspectionFee - (baseInspectionFee * discountPercentage / 100)
      : baseInspectionFee;

    const isInspectionOnly = afterData.completionData?.mode === 0;
    const amount = isInspectionOnly
      ? effectiveInspectionFee
      : (Number(afterData.completionData?.totalCost) || 0) + effectiveInspectionFee;

    const isInApp = IN_APP_PAYMENT_CODES.includes(afterData.paymentModeCode);
    const bookingRef = event.data.after.ref;

    if (amount <= 0) {
      await bookingRef.update({
        walletCreditedAt: admin.firestore.FieldValue.serverTimestamp(),
        walletCreditedAmount: 0,
        walletCreditedTo: agentUid,
        walletCreditedAs: isInApp ? "inApp" : "outsideApp",
      });
      return;
    }

    const walletRef = db.collection("unified_wallets").doc(agentUid);

    try {
      await db.runTransaction(async (tx) => {
        // All reads first — Firestore transactions forbid a read after a write.
        // `getAll` is the documented way to read several documents in one
        // transaction round trip.
        const [bookingSnap, walletSnap] = await tx.getAll(bookingRef, walletRef);

        // Re-check the marker inside the transaction: this trigger fires on every
        // write to the booking, so two invocations can race here.
        if (!bookingSnap.exists || bookingSnap.data().walletCreditedAt) return;

        const increment = admin.firestore.FieldValue.increment(amount);
        const now = admin.firestore.FieldValue.serverTimestamp();

        if (walletSnap.exists) {
          const walletUpdate = {
            totalCompletionAmount: increment,
            lifetimeTotal: increment,
            lastUpdated: now,
          };
          if (isInApp) {
            // In-app earnings are payoutable, so they also raise the balance the
            // technician can request against. Cash stays lifetime-only.
            walletUpdate.inAppEarnings = increment;
            walletUpdate.totalAvailableBalance = increment;
          } else {
            walletUpdate.outsideAppEarnings = increment;
          }
          tx.update(walletRef, walletUpdate);
        } else {
          tx.set(walletRef, {
            workerId: agentUid,
            totalTips: 0.0,
            cardTips: 0.0,
            cashTips: 0.0,
            paidTips: 0.0,
            totalBonus: 0.0,
            paidBonus: 0.0,
            availableBonus: 0.0,
            inAppEarnings: isInApp ? amount : 0.0,
            outsideAppEarnings: isInApp ? 0.0 : amount,
            totalCompletionAmount: amount,
            totalAvailableBalance: isInApp ? amount : 0.0,
            lifetimeTotal: amount,
            payoutRequested: false,
            requestedAmount: 0.0,
            lastUpdated: now,
          });
        }

        tx.update(bookingRef, {
          walletCreditedAt: now,
          walletCreditedAmount: amount,
          walletCreditedTo: agentUid,
          walletCreditedAs: isInApp ? "inApp" : "outsideApp",
        });
      });

      console.log(
        `[${bookingId}] Credited ${amount} to ${agentUid} as ${isInApp ? "in-app" : "outside-app"} earnings`
      );
    } catch (error) {
      console.error(`[${bookingId}] Error crediting unified wallet:`, error);
    }
  }
);

exports.notifyTechnicianOnPaymentCompletion = onDocumentWritten(
  { document: "bookings/{bookingId}", region: FUNCTION_REGION },
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
    let fcmToken;
    let lanCode = "en";
    try {
      const technicianDoc = await admin
        .firestore()
        .collection("users")
        .doc(agent.uid)
        .get();

      if (technicianDoc.exists) {
        technicianData = technicianDoc.data();
        fcmToken = technicianData?.fcmToken;
        lanCode = technicianData?.lanCode || "en";
      } else {
        console.log(`[${bookingId}] Technician document not found`);
      }
    } catch (error) {
      console.error(`[${bookingId}] Error fetching technician data:`, error);
    }

    const serviceName = afterData.service?.name || "Service";
    const serviceNameAr = afterData.service?.name_ar || serviceName;
    const serviceNameUr = afterData.service?.name_ur || serviceNameAr || serviceName;
    const customerName = afterData.customer?.name || "Customer";

    // Get payment amount from completionData
    const inspectionOnly = afterData.completionData?.mode === 0 || false;

    // Calculate effective inspection fee with discount
    const discountPercentage = afterData.service?.discountPercentage || 0;
    const baseInspectionFee = afterData.completionData?.inspectionFee || 0;
    const effectiveInspectionFee = discountPercentage > 0
      ? baseInspectionFee - (baseInspectionFee * discountPercentage / 100)
      : baseInspectionFee;

    const totalAmount = inspectionOnly
      ? effectiveInspectionFee
      : (afterData.completionData?.totalCost || 0) + effectiveInspectionFee;

    // Not gated on the token - the technician app lists what this stores.
    {
      await sendAndStoreNotification({
        targetRole: "technician",
        targetId: agent.uid,
        titleEn: "Payment Received",
        titleAr: "تم استلام الدفع",
        titleUr: "ادائیگی موصول ہو گئی",
        bodyEn: `${customerName} has completed payment for ${serviceName}. The transaction is now complete.`,
        bodyAr: `قام ${customerName} بإكمال الدفع مقابل ${serviceNameAr}. اكتملت المعاملة الآن.`,
        bodyUr: `${customerName} نے ${serviceNameUr} کے لیے ادائیگی مکمل کر لی ہے۔ اب یہ لین دین مکمل ہو گیا ہے۔`,
        data: {
          targetRole: "technician",
          category: "payment",
          bookingId,
          serviceName,
          serviceNameAr: serviceNameAr,
          serviceNameUr: serviceNameUr,
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

    // Determine admin notification texts based on payment method.
    // NOTE: crediting the technician's unified wallet used to live here. It now
    // lives in `creditTechnicianWalletOnPaymentCompletion` above — this function
    // returns early in several places (no FCM token path aside, a warranty claim
    // in any state other than 'A' bails out well before this point), and money
    // must not depend on whether a notification was deliverable.
    const isOutsideApp = !IN_APP_PAYMENT_CODES.includes(afterData.paymentModeCode);

    const adminTitleEn = isOutsideApp ? "Payment received outside app" : "Payment received within app";
    const adminTitleAr = isOutsideApp ? "تم استلام الدفع خارج التطبيق" : "تم استلام الدفع داخل التطبيق";
    const adminTitleUr = isOutsideApp ? "ایپ کے باہر ادائیگی موصول ہوئی" : "ایپ کے اندر ادائیگی موصول ہوئی";

    // Notify admins (excluding customer service)
    try {
      const adminUsersDocs = await getAllAdminUsers();
      const adminTokens = toNotificationRecipients(
        adminUsersDocs.filter((doc) => doc.data().accessLevel !== 2) // Exclude customer service admins
      );

      if (adminTokens.length > 0) {
        await Promise.allSettled(adminTokens.map(async ({ uid, token, lanCode }) => {
          await sendAndStoreNotification({
            targetRole: "admin",
            targetId: uid,
            titleEn: adminTitleEn,
            titleAr: adminTitleAr,
            titleUr: adminTitleUr,
            bodyEn: `${customerName} has completed payment for ${serviceName}. The transaction is now complete.`,
            bodyAr: `قام ${customerName} بإكمال الدفع مقابل ${serviceNameAr}. اكتملت المعاملة الآن.`,
            bodyUr: `${customerName} نے ${serviceNameUr} کے لیے ادائیگی مکمل کر لی ہے۔ اب یہ لین دین مکمل ہو گیا ہے۔`,
            data: {
              targetRole: "admin",
              category: "payment",
              bookingId,
              serviceName,
              serviceNameAr: serviceNameAr,
              serviceNameUr: serviceNameUr,
              customerName,
              amount: totalAmount.toString(),
              isAdmin: "true",
            },
            fcmToken: token,
            lanCode: lanCode,
          });
        }));
        console.log(
          `[${bookingId}] Payment completion notification sent to ${adminTokens.length} admin(s)`
        );
      }
    } catch (error) {
      console.error(`[${bookingId}] Error notifying admins of payment:`, error);
    }
  }
);

exports.customerTrackingNotification = onDocumentWritten(
  { document: "bookings/{bookingId}", region: FUNCTION_REGION },
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
      const customerDoc = await admin.firestore().collection("customers").doc(customerId).get();

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

    // Store even without a token; only the push depends on it.
    if (!fcmToken || fcmToken.trim() === "") {
      console.log(
        `Customer ${customerId} has no valid FCM token; storing notification without a push.`
      );
    }

    const isAccepted = afterData.bookingStatusCode === "A" || afterData.warranty?.warrantyStatusCode === "S";
    if (!isAccepted) {
      console.log("Booking not accepted, skipping tracking notification...");
      return;
    }

    const wasStarted = beforeData?.isStarted;
    const isStartedNow = afterData.isStarted;
    if (wasStarted === isStartedNow) return;

    // Determine titles and bodies for languages
    let titleEn, titleAr, titleUr, bodyEn, bodyAr, bodyUr;

    if (!wasStarted && isStartedNow) {
      titleEn = "Technician is on his way";
      titleAr = "الفني في طريقه إليك";
      titleUr = "ٹیکنیشن راستے میں ہے";
      bodyEn = "The technician is on his way to your service location.";
      bodyAr = "الفني في طريقه إلى موقع الخدمة الخاص بك.";
      bodyUr = "ٹیکنیشن آپ کے سروس کے مقام پر آنے کے راستے میں ہے۔";

      // Reset isNearbySent to false when technician starts tracking
      try {
        await db.collection("bookings").doc(event.params.bookingId).update({
          isNearbySent: false
        });
      } catch (err) {
        console.error("Error resetting isNearbySent:", err);
      }
    } else if (wasStarted && !isStartedNow) {
      titleEn = "Technician Arrived";
      titleAr = "وصل الفني";
      titleUr = "ٹیکنیشن پہنچ گیا";
      bodyEn = "The technician has arrived at your service location.";
      bodyAr = "لقد وصل الفني إلى موقع الخدمة الخاص بك.";
      bodyUr = "ٹیکنیشن آپ کے سروس کے مقام پر پہنچ گیا ہے۔";
    }

    const isWarranty = afterData.warranty?.warrantyStatusCode === "S";
    const reqId = event.params.bookingId + (isWarranty ? "_warranty" : "");

    await sendAndStoreNotification({
      targetRole: "customer",
      targetId: customerId,
      titleEn,
      titleAr,
      titleUr,
      bodyEn,
      bodyAr,
      bodyUr,
      data: {
        requestId: reqId,
        type: "tracking"
      },
      fcmToken: fcmToken,
      lanCode: lanCode,
    });
  }
);
exports.onBookingUpdateToTip = onDocumentWritten(
  { document: "bookings/{bookingId}", region: FUNCTION_REGION },
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
          titleUr: "نئی ٹپ موصول ہوئی",
          bodyEn: `Customer gave you a tip of ${money(tipAmount, "en")}.`,
          bodyAr: `العميل قدّم لك إكرامية بقيمة ${money(tipAmount, "ar")}.`,
          bodyUr: `صارف نے آپ کو ${money(tipAmount, "ur")} کی ٹپ دی ہے۔`,
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
  { document: "bookings/{bookingId}", region: FUNCTION_REGION },
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
  { document: "bookings/{bookingId}", region: FUNCTION_REGION },
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
    const serviceNameUr = booking.service?.name_ur || serviceNameAr || serviceName;
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

    // Not gated on the token: sendAndStoreNotification stores the in-app
    // record before it pushes, so returning here cost an unregistered
    // technician the record too.
    if (!fcmToken || fcmToken.trim() === "") {
      console.log("Worker has no valid FCM token; storing notification without a push.");
    }

    // Prepare notification messages
    await sendAndStoreNotification({
      targetRole: "technician",
      targetId: workerId,
      titleEn: "New Booking Request!",
      titleAr: "طلب حجز جديد!",
      titleUr: "بکنگ کی نئی درخواست!",
      bodyEn: `A customer has requested ${serviceName}. Please review and accept the booking.`,
      bodyAr: `طلب عميل ${serviceNameAr}. يرجى المراجعة وقبول الحجز.`,
      bodyUr: `ایک صارف نے ${serviceNameUr} کے لیے درخواست کی ہے۔ براہ کرم جائزہ لیں اور بکنگ قبول کریں۔`,
      data: {
        targetRole: "technician",
        category: "booking",
        bookingId: bookingId,
        serviceName: serviceName,
        serviceNameAr: serviceNameAr,
        serviceNameUr: serviceNameUr,
        customerName: customerName,
        isAdmin: "false",
      },
      fcmToken: fcmToken,
      lanCode: lanCode,
    });

    return null;
  }
);


exports.notifyWorkerOnTipPayoutProcessed = onDocumentWritten(
  { document: "tipping/{walletId}", region: FUNCTION_REGION },
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

    // notifyTechnicianOnTipPayoutCompletion watches this same document and
    // fires on a strict subset of this condition (the same payoutRequested
    // transition, plus cardtip being cleared). Both notify the technician with
    // different wording, so a card tip payout used to send two notifications.
    // Defer to the more specific one; this branch still covers a payout
    // processed without a card tip balance being cleared.
    const beforeCardTip = beforeData?.cardtip || 0;
    const afterCardTip = afterData.cardtip || 0;
    if (beforeCardTip > 0 && afterCardTip === 0) {
      console.log(
        "Card tip payout handled by notifyTechnicianOnTipPayoutCompletion, skipping duplicate."
      );
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

    // Not gated on the token - see the note on the booking-request
    // notification above.
    if (!fcmToken || fcmToken.trim() === "") {
      console.log("Worker has no valid FCM token; storing notification without a push.");
    }

    // Prepare notification
    const notificationTitle = {
      en: "Tip Payout Processed",
      ar: "تم معالجة سحب الإكرامية",
      ur: "ٹپ کی ادائیگی کی کارروائی مکمل ہو گئی",
    };

    const notificationBody = {
      en: `Your tip payout of ${money(totalTip, "en")} has been processed successfully. The amount will be transferred to your account shortly.`,
      ar: `تم معالجة سحب الإكرامية بمبلغ ${money(totalTip, "ar")} بنجاح. سيتم تحويل المبلغ إلى حسابك قريبًا.`,
      ur: `آپ کی ${money(totalTip, "ur")} کی ٹپ کی ادائیگی کامیابی کے ساتھ ہو گئی ہے۔ یہ رقم جلد ہی آپ کے اکاؤنٹ میں منتقل کر دی جائے گی۔`,
    };

    const title = notificationTitle[lanCode] || notificationTitle["en"];
    const body = notificationBody[lanCode] || notificationBody["en"];

    await sendAndStoreNotification({
      targetRole: "technician",
      targetId: agentId,
      titleEn: notificationTitle["en"],
      titleAr: notificationTitle["ar"],
      titleUr: notificationTitle["ur"],
      bodyEn: notificationBody["en"],
      bodyAr: notificationBody["ar"],
      bodyUr: notificationBody["ur"],
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
  { document: "notification_queue/{docId}", region: FUNCTION_REGION },
  async (event) => {
    const snap = event.data;
    if (!snap) {
      console.log("No data associated with the event");
      return;
    }

    const data = snap.data();
    const docId = event.params.docId;
    const recipientId = data.recipientId;
    
    let targetRole = data.targetRole;
    if (!targetRole) {
      if (data.recipientCollection === 'customers') {
        targetRole = 'customer';
      } else if (data.recipientCollection === 'admins') {
        targetRole = 'admin';
      } else {
        targetRole = 'technician'; // Default
      }
    }

    // Support both old format (single language) and new format (bilingual/trilingual)
    const titleEn = data.titleEn || data.title || null;
    const bodyEn = data.bodyEn || data.body || null;
    const titleAr = data.titleAr || null;
    const bodyAr = data.bodyAr || null;
    const titleUr = data.titleUr || null;
    const bodyUr = data.bodyUr || null;

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
    if ((!titleEn && !titleAr && !titleUr) || (!bodyEn && !bodyAr && !bodyUr)) {
      console.log(
        "Missing required fields - at least one language must have title and body"
      );
      await snap.ref.update({
        processed: true,
        error: "Missing content in all languages",
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return;
    }

    try {
      // Determine collection based on role
      let collectionName = "users";
      if (targetRole === "customer") {
        collectionName = "customers";
      } else if (targetRole === "admin") {
        collectionName = "admins";
      }

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
      } else if (lanCode === "ur" && titleUr && bodyUr) {
        notificationTitle = titleUr;
        notificationBody = bodyUr;
        console.log(
          `Sending Urdu notification to ${targetRole} ${recipientId}`
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
      } else if (titleUr && bodyUr) {
        notificationTitle = titleUr;
        notificationBody = bodyUr;
        console.log(
          `Sending Urdu notification to ${targetRole} ${recipientId}`
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
        titleUr: titleUr,
        bodyUr: bodyUr,
        // Store the sent notification text for history
        sentTitle: notificationTitle,
        sentBody: notificationBody,
        sentLanguage: lanCode,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        // Both apps list notifications with .orderBy('createdAt'), which drops
        // any document missing the field - without this, broadcasts pushed fine
        // but never appeared in the in-app list.
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
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
  { document: "bookings/{bookingId}", region: FUNCTION_REGION },
  async (event) => {
    const beforeSnap = event.data.before;
    const afterSnap = event.data.after;

    if (!beforeSnap || !afterSnap) {
      console.log("No data associated with the event");
      return;
    }

    const beforeData = beforeSnap.data();
    const afterData = afterSnap.data();

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

    if (newCancellations.length === 0) {
      return;
    }

    try {
      // Get the customer data to retrieve FCM token
      const customerId = afterData.customer?.uid;

      if (!customerId) {
        console.log("Customer ID not found in booking data");
        return;
      }

      const customerDoc = await admin.firestore()
        .collection("customers")
        .doc(customerId)
        .get();

      if (!customerDoc.exists) {
        console.log(`Customer document not found for ID: ${customerId}`);
        return;
      }

      const customerData = customerDoc.data();
      const customerFcmToken = customerData.fcmToken;

      // Store even without a token; only the push depends on it.
      if (!customerFcmToken) {
        console.log(
          `Customer ${customerId} has no valid FCM token; storing notification without a push.`
        );
      }

      // Get the worker details who just cancelled
      const lastCancelledWorker = newCancellations[newCancellations.length - 1];
      const afterCancelledCount = afterCancelledWorkers.length;

      if (!lastCancelledWorker) {
        console.log("No cancelled Technician found");
        return;
      }

      // Get service name from ServiceModel
      const serviceData = afterData.service || {};
      const serviceNameEn = serviceData.name || "Service";
      const serviceNameAr = serviceData.name_ar || serviceNameEn;
      const serviceNameUr = serviceData.name_ur || serviceNameAr || serviceNameEn;

      const customerLanCode = customerData.lanCode || "en";

      await sendAndStoreNotification({
        targetRole: "customer",
        targetId: customerId,
        titleEn: "Booking Cancelled",
        titleAr: "تم إلغاء الحجز",
        titleUr: "بکنگ منسوخ کر دی گئی",
        bodyEn: `Technician ${lastCancelledWorker.agentName} cancelled Booking ${afterData.newBookingId || afterData.id}. A new technician will be assigned to your booking shortly.`,
        bodyAr: `لقد قام الفني ${lastCancelledWorker.agentName} بإلغاء الحجز ذو الرقم ${afterData.newBookingId || afterData.id}. سيتم تعيين فني جديد لحجزك قريباً.`,
        bodyUr: `ٹیکنیشن ${lastCancelledWorker.agentName} نے بکنگ آئی ڈی ${afterData.newBookingId || afterData.id} منسوخ کر دی ہے۔ آپ کی بکنگ کے لیے جلد ہی ایک نیا ٹیکنیشن مقرر کیا جائے گا۔`,
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

      // Notify the cancelling technician
      try {
        const workerDoc = await admin.firestore().collection("users").doc(lastCancelledWorker.uid).get();
        if (workerDoc.exists) {
          const workerData = workerDoc.data();
          // Not gated on the token - the technician app lists what this stores.
          {
            await sendAndStoreNotification({
              targetRole: "worker",
              targetId: lastCancelledWorker.uid,
              titleEn: "Booking Cancelled",
              titleAr: "تم إلغاء الحجز",
              titleUr: "بکنگ منسوخ کر دی گئی",
              bodyEn: `You have successfully cancelled Booking ID: ${afterData.newBookingId || afterData.id}.`,
              bodyAr: `لقد قمت بإلغاء الحجز ذو الرقم ${afterData.newBookingId || afterData.id} بنجاح.`,
              bodyUr: `آپ نے بکنگ آئی ڈی ${afterData.newBookingId || afterData.id} کامیابی سے منسوخ کر دی ہے۔`,
              data: {
                bookingId: afterData.id,
                bookingStatusCode: afterData.bookingStatusCode,
              },
              fcmToken: workerData.fcmToken,
              lanCode: workerData.lanCode || "en",
            });
            console.log(`✅ Worker cancellation confirmation sent for booking ${afterData.id} to ${lastCancelledWorker.agentName}`);
          }
        }
      } catch (workerErr) {
        console.error(`❌ Error sending worker cancellation confirmation: ${workerErr}`);
      }
    } catch (error) {
      console.error(
        `❌ Error sending customer cancellation notification: ${error}`
      );
    }
  }
);


exports.notifyAdminsOnWorkerCancellation = onDocumentUpdated(
  { document: "bookings/{bookingId}", region: FUNCTION_REGION },
  async (event) => {
    const beforeSnap = event.data.before;
    const afterSnap = event.data.after;

    if (!beforeSnap || !afterSnap) {
      console.log("No data associated with the event");
      return;
    }

    const beforeData = beforeSnap.data();
    const afterData = afterSnap.data();

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

    if (newCancellations.length === 0) {
      return;
    }

    try {
      // Get the worker details who just cancelled
      const lastCancelledWorker = newCancellations[newCancellations.length - 1];
      const afterCancelledCount = afterCancelledWorkers.length;

      if (!lastCancelledWorker) {
        console.log("No cancelled Technician found");
        return;
      }

      // Get service name from ServiceModel
      const serviceData = afterData.service;
      const serviceName = serviceData.name;
      const serviceNameAr = serviceData.name_ar || serviceData.name;

      // Get customer name
      const customerName = afterData.customer?.name || "Customer";

      // Fetch all admin users with FCM tokens
      const adminUsersDocs = await getAllAdminUsers();
      const adminsWithTokens = adminUsersDocs.filter(
        (doc) => doc.data().fcmToken && doc.data().fcmToken.trim() !== ""
      );

      if (adminsWithTokens.length === 0) {
        console.log("No admin users found with FCM tokens");
      } else {
        // Send notification to each admin
        await Promise.allSettled(adminsWithTokens.map(async (adminDoc) => {
          const adminData = adminDoc.data();
          const adminFcmToken = adminData.fcmToken;
          const adminLanCode = adminData.lanCode || "en";

          await sendAndStoreNotification({
            targetRole: "admin",
            targetId: adminDoc.id,
            titleEn: "Technician Cancelled Booking",
            titleAr: "الفني ألغى الحجز",
            titleUr: "ٹیکنیشن نے بکنگ منسوخ کر دی",
            bodyEn: `Technician ${lastCancelledWorker.agentName} cancelled Booking ID: ${afterData.newBookingId || afterData.id} for customer ${customerName}.`,
            bodyAr: `ألغى الفني ${lastCancelledWorker.agentName} الحجز ذو الرقم ${afterData.newBookingId || afterData.id} للعميل ${customerName}.`,
            bodyUr: `ٹیکنیشن ${lastCancelledWorker.agentName} نے کسٹمر ${customerName} کے لیے بکنگ آئی ڈی ${afterData.newBookingId || afterData.id} منسوخ کر دی ہے۔`,
            data: {
              bookingId: afterData.newBookingId || afterData.id,
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
        }));
        console.log(
          `✅ Admin notifications sent for booking ${afterData.id} - Worker ${lastCancelledWorker.agentName} rejected`
        );
      }

      // --- Trigger Auto-Reassignment Search ---
      const bookingId = afterData.id;
      const bookingDateTime = afterData.bookingDateTime;
      let isInstant = true;
      if (bookingDateTime) {
        const bookingDate = bookingDateTime.toDate();
        isInstant = (bookingDate.getTime() - Date.now()) <= 3 * 60 * 60 * 1000;
      }

      const autoReqRef = db.collection("auto-assignment_requests").doc(bookingId);
      const autoReqData = {
        id: bookingId,
        service: afterData.service || null,
        bookingDateTime: bookingDateTime || null,
        notes: afterData.notes || "",
        issueImage: afterData.issueImage || "",
        issueVideo: afterData.issueVideo || "",
        customer: afterData.customer || null,
        paymentModeCode: afterData.paymentModeCode || "U",
        selectedAddressId: afterData.selectedAddressId || null,
        isOnHour: afterData.isOnHour !== undefined ? afterData.isOnHour : true,
        serviceLocation: afterData.serviceLocation || null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        status: "P",
        type: isInstant ? "instant" : "late",
        notificationSent: false,
        agent: null,
        cancelledWorkerUids: afterData.cancelledWorkerUids || []
      };

      await autoReqRef.set(autoReqData);
      console.log(`[AutoReassign] Created/updated auto-assignment request for cancelled booking ${bookingId}`);

      // Re-enter the auto-assignment cron: back to pending with the booking
      // flagged ready to assign.
      await db.collection("bookings").doc(bookingId).update({
        autoAssignmentStatus: "ready_to_assign",
        bookingStatusCode: "P",
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      console.log(`[AutoReassign] Updated booking ${bookingId} with autoAssignmentStatus ready_to_assign`);

    } catch (error) {
      console.error(
        `❌ Error sending admin cancellation notification / auto-reassign: ${error}`
      );
    }
  }
);

exports.notifyWorkersOnCustomerCancellation = onDocumentUpdated(
  { document: "bookings/{bookingId}", region: FUNCTION_REGION },
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
      const serviceData = afterData.service || {};
      const serviceName = serviceData.name || "Service";
      const serviceNameAr = serviceData.name_ar || serviceName;
      const serviceNameUr = serviceData.name_ur || serviceNameAr || serviceName;

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

        // No `continue` on a missing token: sendAndStoreNotification writes the
        // in-app record before it pushes, so skipping here hid the cancellation
        // from any technician whose device is not registered.

        await sendAndStoreNotification({
          targetRole: "technician",
          targetId: workerDoc.id,
          titleEn: "Booking Cancelled by Customer",
          titleAr: "تم إلغاء الحجز من قبل العميل",
          titleUr: "بکنگ صارف کی طرف سے منسوخ کر دی گئی",
          bodyEn: `Customer ${customerName} cancelled their booking for ${serviceName}. You can no longer accept this booking.`,
          bodyAr: `العميل ${customerName} قام بإلغاء حجز ${serviceNameAr}. لن تتمكن من قبول هذا الحجز.`,
          bodyUr: `صارف ${customerName} نے ${serviceNameUr} کے لیے بکنگ منسوخ کر دی ہے۔ اب آپ اس بکنگ کو قبول نہیں کر سکتے۔`,
          data: {
            bookingId: afterData.id,
            bookingStatusCode: afterData.bookingStatusCode,
            customerName: customerName,
            serviceName: serviceName,
            serviceNameAr: serviceNameAr,
            serviceNameUr: serviceNameUr,
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
  { document: "bookings/{bookingId}", region: FUNCTION_REGION },
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
      const serviceData = afterData.service || {};
      const serviceName = serviceData.name || "Service";
      const serviceNameAr = serviceData.name_ar || serviceName;
      const serviceNameUr = serviceData.name_ur || serviceNameAr || serviceName;

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
      await Promise.allSettled(adminsWithTokens.map(async (adminDoc) => {
        const adminData = adminDoc.data();
        const adminFcmToken = adminData.fcmToken;
        const adminLanCode = adminData.lanCode || "en";

        const cancellationReasonUr = cancellationReason === "Not provided" ? "فراہم نہیں کی گئی" : cancellationReason;

        await sendAndStoreNotification({
          targetRole: "admin",
          targetId: adminDoc.id,
          titleEn: "Booking Cancelled by Customer",
          titleAr: "تم إلغاء الحجز من قبل العميل",
          titleUr: "بکنگ صارف کی طرف سے منسوخ کر دی گئی",
          bodyEn: `Customer ${customerName} cancelled their booking for ${serviceName}. Reason: ${cancellationReason}`,
          bodyAr: `العميل ${customerName} قام بإلغاء حجز ${serviceNameAr}. السبب: ${cancellationReason}`,
          bodyUr: `صارف ${customerName} نے ${serviceNameUr} کے لیے بکنگ منسوخ کر دی ہے۔ وجہ: ${cancellationReasonUr}`,
          data: {
            bookingId: afterData.id,
            bookingStatusCode: afterData.bookingStatusCode,
            customerName: customerName,
            serviceName: serviceName,
            serviceNameAr: serviceNameAr,
            serviceNameUr: serviceNameUr,
            bookingDateTime: afterData.bookingDateTime.toDate().toISOString(),
            cancellationReason: cancellationReason,
            cancelledBy: "customer",
          },
          fcmToken: adminFcmToken,
          lanCode: adminLanCode,
        });
      }));
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

// ============================================
// Warranty Request Notifications
// ============================================
exports.notifyOnWarrantyRequestStatusChange = onDocumentWritten(
  { document: "bookings/{bookingId}", region: FUNCTION_REGION },
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
    // 10. Admin (re)assigns a technician to an already-requested claim.
    // `AssignWarrantyTechnician` writes assignedTechnicianId and leaves the
    // status at 'R' (assignment is not acceptance — the new technician still
    // has to accept). That means this is an R -> R transition, not R -> S, so
    // the previous condition here (which required afterStatusCode === "S")
    // could never fire: any real R -> S transition is already claimed by
    // case 3 above, which runs first in this if/else-if chain. Detecting the
    // *reassignment itself* — most commonly after the first technician
    // rejected the claim — needs to key on the technician id changing while
    // status stays 'R', not on a status transition that doesn't happen.
    else if (
      beforeStatusCode === "R" &&
      afterStatusCode === "R" &&
      afterWarranty.assignedTechnicianId &&
      beforeWarranty?.assignedTechnicianId !== afterWarranty.assignedTechnicianId
    ) {
      status = "warranty_technician_assigned";
      console.log(
        `Warranty technician ${afterWarranty.assignedTechnicianId} (re)assigned to booking ${bookingId}`
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
    const serviceNameUr = afterData.service?.name_ur || serviceName;
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

      adminTokens = toNotificationRecipients(adminUsersDocs);
    } catch (error) {
      console.error("Error fetching admin users:", error);
    }

    // Status-specific messages
    const statusMessages = {
      warranty_available: {
        customer: {
          en: "Your booking is now covered by warranty. You can request free repair within 7 days if needed.",
          ar: "حجزك الآن مشمول بالضمان. يمكنك طلب الإصلاح المجاني خلال 7 أيام إذا لزم الأمر.",
          ur: "آپ کی بکنگ اب وارنٹی میں شامل ہے۔ ضرورت پڑنے پر آپ 7 دن کے اندر مفت مرمت کی درخواست کر سکتے ہیں۔",
        },
        admin: {
          en: `Warranty activated for ${serviceName} - Customer: ${customerName}`,
          ar: `تم تفعيل الضمان لـ ${serviceNameAr} - العميل: ${customerName}`,
          ur: `وارنٹی فعال کر دی گئی برائے ${serviceNameUr} - صارف: ${customerName}`,
        },
      },
      repair_requested: {
        customer: {
          en: "Your warranty repair request has been submitted. We will assign a technician soon.",
          ar: "تم تقديم طلب إصلاح الضمان الخاص بك. سنقوم بتعيين فني قريبًا.",
          ur: "آپ کی وارنٹی مرمت کی درخواست جمع کر دی گئی ہے۔ ہم جلد ہی ایک ٹیکنیشن تفویض کریں گے۔",
        },
        admin: {
          en: `${customerName} requested warranty repair for ${serviceName}`,
          ar: `${customerName} طلب إصلاح الضمان لـ ${serviceNameAr}`,
          ur: `${customerName} نے ${serviceNameUr} کے لیے وارنٹی مرمت کی درخواست کی ہے`,
        },
        technician: {
          en: `Warranty repair requested for ${serviceName}. Customer: ${customerName}`,
          ar: `تم طلب إصلاح الضمان لـ ${serviceNameAr}. العميل: ${customerName}`,
          ur: `${serviceNameUr} کے لیے وارنٹی مرمت کی درخواست کی گئی ہے۔ صارف: ${customerName}`,
        },
      },
      warranty_accepted: {
        customer: {
          en: "Your warranty repair request has been accepted. A technician will contact you soon.",
          ar: "تم قبول طلب إصلاح الضمان الخاص بك. سيتصل بك فني قريبًا.",
          ur: "آپ کی وارنٹی مرمت کی درخواست منظور کر لی گئی ہے۔ ایک ٹیکنیشن جلد ہی آپ سے رابطہ کرے گا۔",
        },
        admin: {
          en: `Warranty repair accepted for ${serviceName} - Customer: ${customerName}`,
          ar: `تم قبول إصلاح الضمان لـ ${serviceNameAr} - العميل: ${customerName}`,
          ur: `${serviceNameUr} کے لیے وارنٹی مرمت منظور کر لی گئی ہے - صارف: ${customerName}`,
        },
      },
      warranty_tracking_started: {
        customer: {
          en: "The technician is on the way for your warranty repair. You can now track their location.",
          ar: "الفني في الطريق لإصلاح الضمان الخاص بك. يمكنك الآن تتبع موقعه.",
          ur: "ٹیکنیشن آپ کی وارنٹی مرمت کے لیے راستے میں ہے۔ اب آپ ان کا مقام ٹریک کر سکتے ہیں۔",
        },
        admin: {
          en: `Technician started tracking for warranty repair - ${serviceName}`,
          ar: `بدأ الفني التتبع لإصلاح الضمان - ${serviceNameAr}`,
          ur: `ٹیکنیشن نے وارنٹی مرمت کے لیے ٹریکنگ شروع کر دی ہے - ${serviceNameUr}`,
        },
      },
      warranty_tracking_stopped: {
        customer: {
          en: "The technician has arrived at your location for warranty repair.",
          ar: "وصل الفني إلى موقعك لإصلاح الضمان.",
          ur: "ٹیکنیشن وارنٹی مرمت کے لیے آپ کے مقام پر پہنچ گیا ہے۔",
        },
        admin: {
          en: `Technician arrived for warranty repair - ${serviceName}`,
          ar: `وصل الفني لإصلاح الضمان - ${serviceNameAr}`,
          ur: `ٹیکنیشن وارنٹی مرمت کے لیے پہنچ گیا ہے - ${serviceNameUr}`,
        },
      },
      warranty_completed: {
        customer: {
          en: "Your warranty repair has been completed successfully. Thank you for using our service!",
          ar: "تم إكمال إصلاح الضمان الخاص بك بنجاح. شكرًا لاستخدام خدمتنا!",
          ur: "آپ کی وارنٹی مرمت کامیابی کے ساتھ مکمل ہو گئی ہے۔ ہماری سروس استعمال کرنے کا شکریہ!",
        },
        admin: {
          en: `Warranty repair completed for ${serviceName} - Customer: ${customerName}`,
          ar: `تم إكمال إصلاح الضمان لـ ${serviceNameAr} - العميل: ${customerName}`,
          ur: `${serviceNameUr} کے لیے وارنٹی مرمت مکمل ہو گئی ہے - صارف: ${customerName}`,
        },
      },
      warranty_rejected: {
        customer: {
          en: "Your warranty repair request has been rejected by the administrator.",
          ar: "تم رفض طلب إصلاح الضمان الخاص بك من قبل المسؤول.",
          ur: "آپ کی وارنٹی مرمت کی درخواست ایڈمنسٹریٹر کی طرف سے مسترد کر دی گئی ہے۔",
        },
        admin: {
          en: `Warranty repair rejected for ${serviceName} - Customer: ${customerName}`,
          ar: `تم رفض إصلاح الضمان لـ ${serviceNameAr} - العميل: ${customerName}`,
          ur: `${serviceNameUr} کے لیے وارنٹی مرمت مسترد کر دی گئی ہے - صارف: ${customerName}`,
        },
      },
      warranty_expired: {
        customer: {
          en: "Your warranty period has expired (7 days). You can no longer request repair under warranty.",
          ar: "انتهت فترة الضمان الخاصة بك (7 أيام). لم يعد بإمكانك طلب الإصلاح بموجب الضمان.",
          ur: "آپ کی وارنٹی کی مدت ختم ہو چکی ہے (7 دن)۔ اب آپ وارنٹی کے تحت مرمت کی درخواست نہیں کر سکتے۔",
        },
        admin: {
          en: `Warranty expired for ${serviceName} - Customer: ${customerName}`,
          ar: `انتهى الضمان لـ ${serviceNameAr} - العميل: ${customerName}`,
          ur: `${serviceNameUr} کے لیے وارنٹی ختم ہو گئی ہے - صارف: ${customerName}`,
        },
      },
      warranty_technician_assigned: {
        customer: {
          en: "A new technician has been assigned to your warranty repair. They will contact you soon.",
          ar: "تم تعيين فني جديد لإصلاح الضمان الخاص بك. سيتصل بك قريبًا.",
          ur: "آپ کی وارنٹی مرمت کے لیے ایک نیا ٹیکنیشن تفویض کر دیا گیا ہے۔ وہ جلد ہی آپ سے رابطہ کرے گا۔",
        },
        admin: {
          en: `New technician assigned to warranty repair for ${serviceName} - Customer: ${customerName}`,
          ar: `تم تعيين فني جديد لإصلاح الضمان لـ ${serviceNameAr} - العميل: ${customerName}`,
          ur: `${serviceNameUr} کے لیے وارنٹی مرمت میں نیا ٹیکنیشن تفویض کر دیا گیا ہے - صارف: ${customerName}`,
        },
      },
      technician_rejected: {
        customer: {
          en: `Technician ${notificationData.rejectedTechnicianName || "has"
            } declined your warranty repair request. We are assigning another technician.`,
          ar: `رفض الفني ${notificationData.rejectedTechnicianName || ""
            } طلب إصلاح الضمان الخاص بك. نحن نقوم بتعيين فني آخر.`,
          ur: `ٹیکنیشن ${notificationData.rejectedTechnicianName || "نے"
            } نے آپ کی وارنٹی مرمت کی درخواست مسترد کر دی ہے۔ ہم ایک اور ٹیکنیشن تفویض کر رہے ہیں۔`,
        },
        admin: {
          en: `Technician ${notificationData.rejectedTechnicianName || "Unknown"
            } rejected warranty repair for ${serviceName}. Reason: ${notificationData.rejectionReason || "Not specified"
            }`,
          ar: `رفض الفني ${notificationData.rejectedTechnicianName || "غير معروف"
            } إصلاح الضمان لـ ${serviceNameAr}. السبب: ${notificationData.rejectionReason || "غير محدد"
            }`,
          ur: `ٹیکنیشن ${notificationData.rejectedTechnicianName || "نامعلوم"
            } نے ${serviceNameUr} کے لیے وارنٹی مرمت مسترد کر دی ہے۔ وجہ: ${notificationData.rejectionReason || "غیر متعین"
            }`,
        },
      },
    };

    // Notify customer. Not gated on the token: the in-app notifications list
    // reads what this stores, so a customer whose device was never registered
    // must still get the record even though there is no push to send.
    if (customerId) {
      const customerLanCode = customerData?.lanCode || "en";

      await sendAndStoreNotification({
        targetRole: "customer",
        targetId: customerId,
        titleEn: "Warranty Update",
        titleAr: "تحديث الضمان",
        titleUr: "وارنٹی اپ ڈیٹ",
        bodyEn:
          statusMessages[status]?.customer?.["en"] ||
          `Your warranty status has been updated`,
        bodyAr:
          statusMessages[status]?.customer?.["ar"] ||
          `تم تحديث حالة الضمان الخاصة بك`,
        bodyUr:
          statusMessages[status]?.customer?.["ur"] ||
          `آپ کی وارنٹی کی صورتحال اپ ڈیٹ کر دی گئی ہے`,
        data: {
          targetRole: "customer",
          category: "warranty",
          bookingId: bookingId,
          status: status,
          warrantyStatusCode: afterStatusCode,
          serviceName: serviceName,
          isWarranty: "true",
          requestId: `${bookingId}_warranty_${status}`,
          ...notificationData,
        },
        fcmToken: customerData?.fcmToken,
        lanCode: customerLanCode,
      });
    }

    // Notify technician
    if (workerId && statusMessages[status]?.technician) {
      try {
        const techDoc = await admin
          .firestore()
          .collection("users")
          .doc(workerId)
          .get();
        if (techDoc.exists) {
          const techData = techDoc.data();
          // Not gated on the token - the technician app lists what this stores.
          {
            await sendAndStoreNotification({
              targetRole: "technician",
              targetId: workerId,
              titleEn: "Warranty Update",
              titleAr: "تحديث الضمان",
              titleUr: "وارنٹی اپ ڈیٹ",
              bodyEn:
                statusMessages[status].technician["en"] ||
                `Warranty status updated for booking ${bookingId}`,
              bodyAr:
                statusMessages[status].technician["ar"] ||
                `تم تحديث حالة الضمان للحجز ${bookingId}`,
              bodyUr:
                statusMessages[status].technician["ur"] ||
                `بکنگ ${bookingId} کے لیے وارنٹی کی صورتحال اپ ڈیٹ کر دی گئی ہے`,
              data: {
                targetRole: "technician",
                category: "warranty",
                bookingId: bookingId,
                customerId: customerId || "",
                status: status,
                warrantyStatusCode: afterStatusCode,
                serviceName: serviceName,
                isWarranty: "true",
                requestId: `${bookingId}_warranty_${status}`,
                ...notificationData,
              },
              fcmToken: techData.fcmToken,
              lanCode: techData.lanCode || "en",
            });
          }
        }
      } catch (error) {
        console.error("Error fetching technician data:", error);
      }
    }

    // Notify admins
    if (adminTokens.length > 0) {
      await Promise.allSettled(adminTokens.map(async ({ uid, token, lanCode }) => {
        await sendAndStoreNotification({
          targetRole: "admin",
          targetId: uid,
          titleEn: "Warranty Update",
          titleAr: "تحديث الضمان",
          titleUr: "وارنٹی اپ ڈیٹ",
          bodyEn:
            statusMessages[status]?.admin?.["en"] ||
            `Warranty status updated for booking ${bookingId}`,
          bodyAr:
            statusMessages[status]?.admin?.["ar"] ||
            `تم تحديث حالة الضمان للحجز ${bookingId}`,
          bodyUr:
            statusMessages[status]?.admin?.["ur"] ||
            `بکنگ ${bookingId} کے لیے وارنٹی کی صورتحال اپ ڈیٹ کر دی گئی ہے`,
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
            requestId: `${bookingId}_warranty_${status}`,
            ...notificationData,
          },
          fcmToken: token,
          lanCode: lanCode,
        });
      }));
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
  { document: "bookings/{bookingId}", region: FUNCTION_REGION },
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
    const serviceNameAr = afterData.service?.name_ar || serviceName;
    const serviceNameUr = afterData.service?.name_ur || serviceNameAr || serviceName;
    const customerName = afterData.customer?.name || "Customer";
    const warranty = afterData.warranty;

    // Determine escalation reason
    let escalationReason = "staying unchanged (unattended) for a long time";
    if (
      warranty?.rejectedTechnicians &&
      warranty.rejectedTechnicians.length > 0
    ) {
      escalationReason = "the original technician cancelled/rejected the request";
    }

    // Fetch all admin users
    let adminTokens = [];
    try {
      const adminUsersDocs = await getAllAdminUsers();

      adminTokens = toNotificationRecipients(adminUsersDocs);
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
    const titleUr = "⚠️ وارنٹی کی درخواست کو بڑھا دیا گیا";

    const bodyEn = `A warranty request for "${serviceName}" from ${customerName} with booking id ${afterData.newBookingId || bookingId} requires your attention. Reason: ${escalationReason}.`;

    const arReason = escalationReason === "staying unchanged (unattended) for a long time"
      ? "ترك هذا الطلب دون تغيير (غير مُعالج) لفترة طويلة"
      : "إلغاء/رفض الطلب من قبل الفني الأصلي";
    const bodyAr = `طلب ضمان لـ "${serviceNameAr}" من ${customerName} برقم الحجز ${afterData.newBookingId || bookingId} يتطلب انتباهك. السبب: ${arReason}.`;

    const urReason = escalationReason === "staying unchanged (unattended) for a long time"
      ? "اس درخواست کو طویل عرصے سے بغیر تبدیلی (غیر حل شدہ) چھوڑ دیا گیا ہے"
      : "اصل ٹیکنیشن نے درخواست کو منسوخ/مسترد کر دیا ہے";
    const bodyUr = `"${serviceNameUr}" کے لیے ${customerName} کی طرف سے وارنٹی کی درخواست بکنگ آئی ڈی ${afterData.newBookingId || bookingId} کے ساتھ آپ کی توجہ کی طلبگار ہے۔ وجہ: ${urReason}۔`;

    // Send notification to each admin
    await Promise.allSettled(adminTokens.map(async ({ uid, token, lanCode }) => {
      await sendAndStoreNotification({
        targetRole: "admin",
        targetId: uid,
        titleEn: titleEn,
        titleAr: titleAr,
        titleUr: titleUr,
        bodyEn: bodyEn,
        bodyAr: bodyAr,
        bodyUr: bodyUr,
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
    }));

    console.log(
      `✅ Escalation notifications sent to ${adminTokens.length} admin(s) for booking ${bookingId}`
    );

    return null;
  }
);

// ============================================
// Notify Customer on Warranty Resolution
// ============================================
exports.notifyCustomerOnWarrantyResolution = onDocumentWritten(
  { document: "bookings/{bookingId}", region: FUNCTION_REGION },
  async (event) => {
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();
    const bookingId = event.params.bookingId;

    if (!afterData || !beforeData) {
      return null;
    }

    // Check if isEscalated changed from true to false
    const wasEscalated = beforeData.isEscalated === true;
    const isEscalatedNow = afterData.isEscalated === true;

    if (!wasEscalated || isEscalatedNow) {
      return null; // No resolution occurred
    }

    console.log(`Warranty request resolved for booking ${bookingId}. Notifying customer...`);

    const customer = afterData.customer;
    if (!customer || !customer.uid) {
      console.log("Customer data missing, cannot send notification.");
      return null;
    }

    const serviceName = afterData.service?.name || "Service";
    const serviceNameAr = afterData.service?.name_ar || serviceName;
    const serviceNameUr = afterData.service?.name_ur || serviceNameAr || serviceName;
    const resolutionText = afterData.resolutionText || "Issue resolved";

    const titleEn = "✅ Warranty Issue Resolved";
    const titleAr = "✅ تم حل مشكلة الضمان";
    const titleUr = "✅ وارنٹی کا مسئلہ حل ہو گیا";

    const bodyEn = `Your escalated warranty issue for "${serviceName}" has been resolved by our admin. Resolution: ${resolutionText}`;
    const bodyAr = `تم حل مشكلة الضمان المصعدة لـ "${serviceNameAr}" من قبل الإدارة. الحل: ${resolutionText}`;
    const bodyUr = `آپ کے "${serviceNameUr}" کے لیے وارنٹی کے مسئلے کو ہمارے ایڈمن نے حل کر دیا ہے۔ حل: ${resolutionText}`;

    await sendAndStoreNotification({
      targetRole: "customer",
      targetId: customer.uid,
      titleEn: titleEn,
      titleAr: titleAr,
      titleUr: titleUr,
      bodyEn: bodyEn,
      bodyAr: bodyAr,
      bodyUr: bodyUr,
      data: {
        targetRole: "customer",
        category: "warranty_resolution",
        bookingId: bookingId,
        isWarranty: "true",
      },
      fcmToken: customer.fcmToken || "",
      lanCode: customer.lanCode || "en",
    });

    console.log(`✅ Resolution notification sent to customer for booking ${bookingId}`);

    return null;
  }
);

// ============================================
// Counter Offer Notifications
// ============================================
exports.notifyOnCounterOfferCreated = onDocumentCreated(
  { document: "counter_offers/{offerId}", region: FUNCTION_REGION },
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

      if (!targetId) {
        console.log(`No ${targetRole} to notify`);
        return null;
      }

      // A missing token is not a reason to bail: sendAndStoreNotification
      // writes the in-app record before it pushes, so returning here cost the
      // recipient their notification history as well as the push.
      if (!fcmToken || fcmToken.trim() === '') {
        console.log(`No valid FCM token for ${targetRole} ${targetId}; storing notification without a push`);
      }

      const serviceName = bookingData.service?.name || 'Service';
      const serviceNameAr = bookingData.service?.name_ar || serviceName;
      const serviceNameUr = bookingData.service?.name_ur || serviceNameAr || serviceName;
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
        titleUr: 'متبادل وقت کی تجویز',
        bodyEn: `${proposedByName} has proposed a new time: ${timeString} for ${serviceName}`,
        bodyAr: `اقترح ${proposedByName} وقتاً جديداً: ${timeString} لـ ${serviceNameAr}`,
        bodyUr: `${proposedByName} نے ${serviceNameUr} کے لیے ایک نیا وقت تجویز کیا ہے: ${timeString}`,
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
          serviceNameUr,
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
  { document: "counter_offers/{offerId}", region: FUNCTION_REGION },
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

      if (!targetId) {
        console.log(`No ${targetRole} to notify`);
        return null;
      }

      // A missing token is not a reason to bail: sendAndStoreNotification
      // writes the in-app record before it pushes, so returning here cost the
      // recipient their notification history as well as the push.
      if (!fcmToken || fcmToken.trim() === '') {
        console.log(`No valid FCM token for ${targetRole} ${targetId}; storing notification without a push`);
      }

      const serviceName = bookingData.service?.name || 'Service';
      const serviceNameAr = bookingData.service?.name_ar || serviceName;
      const serviceNameUr = bookingData.service?.name_ur || serviceNameAr || serviceName;
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
      const statusTextUr = newStatus === 'accepted' ? 'قبول' : 'مسترد';

      await sendAndStoreNotification({
        targetRole,
        targetId,
        titleEn: 'Counter Offer Response',
        titleAr: 'الرد على الاقتراح البديل',
        titleUr: 'جوابی پیشکش کا جواب',
        bodyEn: `${proposedByName} has ${statusTextEn} your proposed time: ${timeString} for ${serviceName}`,
        bodyAr: `${proposedByName} قام بـ ${statusTextAr} الوقت المقترح: ${timeString} لـ ${serviceNameAr}`,
        bodyUr: `${proposedByName} نے ${serviceNameUr} کے لیے آپ کا تجویز کردہ وقت ${timeString} ${statusTextUr} کر دیا ہے`,
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
  {
    ref: "messages/{chatId}/{messageId}",
    instance: "worker-app-tnext-default-rtdb",
    region: "us-central1",
  },
  async (event) => {
    const chatId = event.params.chatId;
    const messageId = event.params.messageId;
    const messageData = event.data.val();

    if (!messageData) {
      console.log(`[${chatId}] No message data found`);
      return null;
    }

    const senderId = messageData.senderId;
    let senderType = messageData.senderType; // 'technician', 'admin', or 'customer'
    const messageText = messageData.text || "";
    const mediaType = messageData.mediaType;

    console.log(
      `[${chatId}] New message from ${senderType} (${senderId}): ${messageText}`
    );

    try {
      // Get chat details from Realtime Database
      const rtdb = getRtdb();
      const chatSnapshot = await rtdb.ref(`chats/${chatId}`).once("value");

      const chatData = chatSnapshot.exists() ? chatSnapshot.val() : {};
      const participants = chatData.participants || {};

      // Determine the receiver by ROLE. Never by "the uid that is not the
      // sender" - that question has no answer when both roles are held by the
      // same person, which is exactly what phone auth on a shared project
      // produces.
      const senderRole = CHAT_ROLES.includes(senderType)
        ? senderType
        : participantUid(participants, "customer") === senderId
          ? "customer"
          : "technician";

      // The counterpart of a customer is the technician, or the admin when the
      // chat is a support conversation; everyone else's counterpart is the
      // customer. Never "the uid that is not the sender" - that question has no
      // answer when both roles are held by the same person, which is exactly
      // what phone auth on a shared project produces.
      let receiverType = null;
      let receiverId = null;

      if (senderRole === "customer") {
        for (const role of ["technician", "admin"]) {
          const uid = participantUid(participants, role);
          if (uid) {
            receiverType = role;
            receiverId = uid;
            break;
          }
        }
      } else {
        receiverId = participantUid(participants, "customer");
        if (receiverId) receiverType = "customer";
      }

      // Nothing named: leave the role at the ordinary counterpart so the
      // recovery below loads the right profile collection rather than whichever
      // role the search happened to give up on.
      if (!receiverId) {
        receiverType = senderRole === "customer" ? "technician" : "customer";
      }

      // The chat metadata node is not a dependency of delivering the message.
      //
      // It can legitimately be missing or half-written: a client that reuses a
      // stale `chatroomId` never calls createChat, so nothing writes
      // `participants`, and `markAsRead` can create `chats/<id>` holding
      // nothing but an unread counter - which exists but names nobody. Bailing
      // out here used to drop the push silently, and the very first message of
      // a conversation is exactly when this node is most likely to be absent.
      //
      // The id itself carries the answer. `generateChatId` builds
      // `<bookingId>_<uidA>_<uidB>` from the two sorted uids, and Firebase Auth
      // uids never contain an underscore, so the last two segments are the
      // participants no matter what the booking id looks like.
      if (!receiverId) {
        const segments = chatId.split("_");
        if (segments.length >= 3) {
          const pair = segments.slice(-2);
          // Only trust the pair if the sender is in it AND the two uids differ.
          // `<booking>_<uid>_<uid>` names one person twice, so there is no
          // second party to recover and guessing would push the message back
          // to its own sender.
          if (pair.includes(senderId) && pair[0] !== pair[1]) {
            receiverId = pair.find((uid) => uid && uid !== senderId) || null;
          }
        }
        if (receiverId) {
          console.warn(
            `[${chatId}] Chat participants unreadable (chat node ${chatSnapshot.exists() ? "incomplete" : "missing"}); recovered receiver ${receiverId} from the chat id`
          );
        }
      }

      if (!receiverId) {
        console.log(`[${chatId}] No receiver found`);
        return null;
      }

      // `receiverType` is one of the three roles by construction above, so it
      // needs no further guarding. `senderType` came off the message and may be
      // missing or junk; `senderRole` is the validated version of it.
      senderType = senderRole;

      console.log(`[${chatId}] Receiver: ${receiverType} (${receiverId})`);

      // Chat is by far the highest-volume trigger here, so both profiles and
      // the booking are read exactly once and concurrently. This used to be
      // four sequential document reads - sender and receiver were each fetched
      // twice, once for the name and again further down for the photo.
      const profileCollection = (role) =>
        role === "customer" ? "customers" : role === "admin" ? "admins" : "users";

      const loadProfile = async (uid, role, whenMissing, whenNameless) => {
        try {
          const doc = await db.collection(profileCollection(role)).doc(uid).get();
          if (!doc.exists) {
            return { name: whenMissing, photo: "", fcmToken: null, lanCode: "en" };
          }
          const d = doc.data();
          return {
            name: d.name || d.fullName || whenNameless,
            photo: d.photo || "",
            fcmToken: d.fcmToken || null,
            lanCode: d.lanCode || "en",
          };
        } catch (error) {
          // A profile we cannot read only costs the push and some cosmetic
          // fields; the notification itself still gets stored.
          console.error(`[${chatId}] Error loading ${role} profile ${uid}:`, error);
          return { name: whenMissing, photo: "", fcmToken: null, lanCode: "en" };
        }
      };

      // Same recovery for the booking id: it prefixes the chat id, so a
      // missing chat node costs the payload nothing.
      const bookingId =
        chatData.bookingId || chatId.split("_").slice(0, -2).join("_") || "";

      const [sender, receiver, bookingDoc] = await Promise.all([
        loadProfile(
          senderId,
          senderType,
          "Someone",
          senderType === "customer" ? "Customer" : "Technician"
        ),
        loadProfile(
          receiverId,
          receiverType,
          "User",
          receiverType === "customer"
            ? "Customer"
            : receiverType === "admin"
              ? "Admin"
              : "Technician"
        ),
        bookingId
          ? db
              .collection("bookings")
              .doc(bookingId)
              .get()
              .catch((e) => {
                console.error(`[${chatId}] Error fetching booking details:`, e);
                return null;
              })
          : null,
      ]);

      const senderName = sender.name;
      const senderPhoto = sender.photo;
      const receiverName = receiver.name;
      const receiverPhoto = receiver.photo;
      const receiverFcmToken = receiver.fcmToken;
      const receiverLanCode = receiver.lanCode;

      let serviceName = "Service";
      let isWarranty = "false";
      if (bookingDoc && bookingDoc.exists) {
        const bookingData = bookingDoc.data();
        serviceName = bookingData.service?.name || "Service";
        if (bookingData.warranty) {
          isWarranty = "true";
        }
      }

      if (!receiverFcmToken || receiverFcmToken.trim() === "") {
        console.log(
          `[${chatId}] Receiver ${receiverId} has no valid FCM token; storing the notification without a push.`
        );
      }


      // Prepare notification message
      let bodyEn = messageText;
      let bodyAr = messageText;
      let bodyUr = messageText;

      // Handle media messages
      if (mediaType === "image") {
        bodyEn = "📷 Photo";
        bodyAr = "📷 صورة";
        bodyUr = "📷 تصویر";
      } else if (mediaType === "video") {
        bodyEn = "🎥 Video";
        bodyAr = "🎥 فيديو";
        bodyUr = "🎥 ویڈیو";
      }

      // Truncate long messages
      if (bodyEn.length > 100) {
        bodyEn = bodyEn.substring(0, 97) + "...";
        bodyAr = bodyAr.substring(0, 97) + "...";
        bodyUr = bodyUr.substring(0, 97) + "...";
      }

      const titleEn = `New message from ${senderName}`;
      const titleAr = `رسالة جديدة من ${senderName}`;
      const titleUr = `${senderName} کی طرف سے نیا پیغام`;

      // Put the metadata node back if it was the thing that was broken. The
      // notification above does not depend on it, but everything else does -
      // the chat list, unread counts, and deleteChatFromRTDB, which reads
      // `participants` to know whose userChats entries to remove.
      const namedRoles = CHAT_ROLES.filter((role) =>
        participantUid(participants, role)
      ).length;
      if (!chatSnapshot.exists() || namedRoles < 2) {
        try {
          await rtdb.ref(`chats/${chatId}`).update({
            bookingId: bookingId,
            participants: {
              [senderRole]: senderId,
              [receiverType]: receiverId,
            },
          });
          console.log(`[${chatId}] Repaired chat metadata node`);
        } catch (repairError) {
          console.error(`[${chatId}] Could not repair chat node:`, repairError);
        }
      }

      await sendAndStoreNotification({
        targetRole: receiverType,
        targetId: receiverId,
        titleEn: titleEn,
        titleAr: titleAr,
        titleUr: titleUr,
        bodyEn: bodyEn,
        bodyAr: bodyAr,
        bodyUr: bodyUr,
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
        sendPush: true,
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

// Which bonus scheme is live.
//
//   "hourly"  -> `applyHourlyBonus` pays every hour on the hour for the hour
//                just ended, evaluated against the jobs done in that 1-hour window.
//   "daily"   -> `applyDailyBonus` pays every night for the day just ended,
//                on the 10/12/60 job ladder.
//   "monthly" -> `applyMonthlyBonus` pays once, on the 1st, for the whole
//                previous month, on the original 20/40/60 ladder.
//
// ALL functions stay deployed so switching is a one-line change plus a
// redeploy — no function has to be recreated and no Cloud Scheduler job has to
// be rebuilt. Inactive functions exit immediately on every invocation.
const BONUS_MODE = "hourly"; // "hourly" | "daily" | "monthly"

// Tier qualification thresholds, evaluated against the worker's month-to-date
// job count (`currentMonthJobs`) and their overall average rating across all schemes.
const TIER_JOB_LADDERS = {
  hourly: { silver: 3, gold: 5, platinum: 10 },
  daily: { silver: 10, gold: 12, platinum: 60 },
  monthly: { silver: 20, gold: 40, platinum: 60 },
};
const TIER_JOBS = TIER_JOB_LADDERS[BONUS_MODE];

const TIER_SILVER_JOBS = TIER_JOBS.silver;
const TIER_SILVER_RATING = 4.0;
const TIER_GOLD_JOBS = TIER_JOBS.gold;
const TIER_GOLD_RATING = 4.5;
const TIER_PLATINUM_JOBS = TIER_JOBS.platinum;
const TIER_PLATINUM_RATING = 4.8;

/**
 * The one place a tier is decided.
 *
 * Both the live tier badge (`updateWorkerTierOnJobCompletion`, which recomputes
 * on every completed job) and the nightly bonus run read this. They used to
 * carry separate copies of the same ladder, so the tier a worker was shown and
 * the tier they were paid for could disagree after any edit to one of them.
 */
function resolveTier(jobs, averageRating) {
  if (averageRating >= TIER_PLATINUM_RATING && jobs >= TIER_PLATINUM_JOBS) {
    return { tier: "Platinum", bonusPercentage: 0.15 };
  }
  if (averageRating >= TIER_GOLD_RATING && jobs >= TIER_GOLD_JOBS) {
    return { tier: "Gold", bonusPercentage: 0.1 };
  }
  if (averageRating >= TIER_SILVER_RATING && jobs >= TIER_SILVER_JOBS) {
    return { tier: "Silver", bonusPercentage: 0.05 };
  }
  return { tier: "Bronze", bonusPercentage: 0 };
}

/**
 * Resolves the effective inspection fee for bonus calculation.
 * If the charged inspection fee is 0 (e.g. on-hour / off-hour fee is 0),
 * falls back to the service general price (completionData.generalServicePrice,
 * booking.service.price, or fetches from services collection).
 */
async function resolveInspectionFeeForBonus(booking) {
  const chargedInspectionFee = Number(booking.completionData?.inspectionFee) || 0;
  let baseFee = chargedInspectionFee;

  if (baseFee <= 0) {
    baseFee = Number(booking.completionData?.generalServicePrice) || 0;
  }
  if (baseFee <= 0 && booking.service?.price != null) {
    baseFee = Number(booking.service.price) || 0;
  }
  if (baseFee <= 0 && booking.service?.id) {
    try {
      const serviceDoc = await db.collection("services").doc(booking.service.id).get();
      if (serviceDoc.exists) {
        baseFee = Number(serviceDoc.data()?.price) || 0;
      }
    } catch (err) {
      logger.warn(`Could not fetch general service price for ${booking.service.id}:`, err);
    }
  }

  const discountPercentage = Number(booking.service?.discountPercentage) || 0;
  const effectiveFee = discountPercentage > 0
    ? baseFee - (baseFee * discountPercentage) / 100
    : baseFee;

  return effectiveFee > 0 ? effectiveFee : 0;
}

/**
 * Resolves the effective inspection fee from a `completedJobs` array entry.
 * Uses `generalPrice` when `inspectionFee` is 0, and applies the discount
 * percentage stored on the entry.
 */
function resolveInspectionFeeFromEntry(entry) {
  let baseFee = Number(entry.inspectionFee) || 0;
  if (baseFee <= 0) {
    baseFee = Number(entry.generalPrice) || 0;
  }
  const discountPercentage = Number(entry.discountPercentage) || 0;
  const effectiveFee = discountPercentage > 0
    ? baseFee - (baseFee * discountPercentage) / 100
    : baseFee;
  return effectiveFee > 0 ? effectiveFee : 0;
}

/**
 * Shared bonus calculation and crediting logic used by all three bonus modes
 * (hourly, daily, monthly). Each mode calls this with a different
 * `idempotencyField` / `idempotencyValue` pair so the same run is never paid
 * twice, but the same month-to-date logic applies identically.
 *
 * Flow:
 *  1. Iterate every user who has `completedJobs` entries.
 *  2. Sum the effective inspection fees from the list.
 *  3. Resolve the tier from `currentMonthJobs` + average rating.
 *  4. Calculate the full month-to-date bonus = totalFees × bonusPercentage.
 *  5. Credit only the unpaid delta = fullBonus − totalMonthlyBonus.
 *  6. Update the user document & unified wallet, send notification.
 */
async function calculateAndApplyBonuses({
  idempotencyField,
  idempotencyValue,
  logLabel,
  targetMonthKey = ksaMonthKey(Date.now()),
}) {
  logger.info(
    `Calculating bonuses (${logLabel}) for ${idempotencyValue} in month ${targetMonthKey}...`
  );

  const usersSnapshot = await db.collection("users").get();
  let totalBonusesApplied = 0;
  let totalBonusAmount = 0;

  for (const userDoc of usersSnapshot.docs) {
    const userId = userDoc.id;
    try {
      const userData = userDoc.data() || {};

      // Quick filter: only process if the technician has a monthly record
      const monthRecordRef = db
        .collection("users")
        .doc(userId)
        .collection("monthly_records")
        .doc(targetMonthKey);

      const monthRecordSnap = await monthRecordRef.get();
      if (!monthRecordSnap.exists) {
        continue; // No jobs recorded for this month
      }

      const monthData = monthRecordSnap.data() || {};

      // Idempotency: skip if already paid for this cycle
      if (monthData[idempotencyField] === idempotencyValue) {
        logger.info(
          `Bonus already applied to ${userId} for ${idempotencyValue} in ${targetMonthKey}`
        );
        continue;
      }

      const completedJobs = monthData.completedJobs;
      if (!Array.isArray(completedJobs) || completedJobs.length === 0) {
        continue;
      }

      // Sum effective inspection fees from the subcollection list
      let totalInspectionFees = 0;
      for (const entry of completedJobs) {
        totalInspectionFees += resolveInspectionFeeFromEntry(entry);
      }

      if (totalInspectionFees <= 0) continue;

      // Tier from month-to-date job count + average rating
      const effectiveJobs =
        monthData.jobsCount ||
        completedJobs.length ||
        userData.currentMonthJobs ||
        0;
      const ratingSum = userData.rating || 0.0;
      const reviewCount = userData.reviewCount || 0;
      const averageRating = reviewCount > 0 ? ratingSum / reviewCount : 5.0;

      const { tier, bonusPercentage } = resolveTier(effectiveJobs, averageRating);
      if (bonusPercentage === 0) {
        logger.info(
          `User ${userId} in Bronze tier for ${idempotencyValue} in ${targetMonthKey}. No bonus.`
        );
        continue;
      }

      // Full month-to-date bonus
      const fullBonus = totalInspectionFees * bonusPercentage;
      const alreadyPaid =
        Number(monthData.totalMonthlyBonus) ||
        Number(userData.totalMonthlyBonus) ||
        0;

      const delta = fullBonus - alreadyPaid;
      if (delta <= 0) {
        logger.info(
          `User ${userId}: full bonus SAR ${fullBonus.toFixed(2)} already covered by paid SAR ${alreadyPaid.toFixed(2)}. Skipping.`
        );
        continue;
      }

      const roundedDelta = Number(delta.toFixed(2));
      const roundedFullBonus = Number(fullBonus.toFixed(2));

      // 1. Update subcollection document
      await monthRecordRef.update({
        totalMonthlyBonus: roundedFullBonus,
        bonusAmount: roundedDelta,
        totalInspectionFees: totalInspectionFees,
        tier: tier,
        bonusPercentage: bonusPercentage,
        [idempotencyField]: idempotencyValue,
        lastBonusDate: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 2. Update user root document (for fast UI display and balance)
      const userRef = db.collection("users").doc(userId);
      await userRef.update({
        totalMonthlyBonus: roundedFullBonus,
        bonusAmount: roundedDelta,
        availableBalance: admin.firestore.FieldValue.increment(roundedDelta),
        tier: tier,
        lastBonusDate: admin.firestore.FieldValue.serverTimestamp(),
        [idempotencyField]: idempotencyValue,
        lastBonusTier: tier,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 3. Update unified wallet
      try {
        const walletRef = db.collection("unified_wallets").doc(userId);
        await db.runTransaction(async (transaction) => {
          const walletDoc = await transaction.get(walletRef);
          if (walletDoc.exists) {
            transaction.update(walletRef, {
              totalBonus: admin.firestore.FieldValue.increment(roundedDelta),
              availableBonus: admin.firestore.FieldValue.increment(roundedDelta),
              totalAvailableBalance: admin.firestore.FieldValue.increment(roundedDelta),
              lifetimeTotal: admin.firestore.FieldValue.increment(roundedDelta),
              lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
            });
          } else {
            transaction.set(walletRef, {
              workerId: userId,
              totalTips: 0.0,
              cardTips: 0.0,
              cashTips: 0.0,
              paidTips: 0.0,
              totalBonus: roundedDelta,
              paidBonus: 0.0,
              availableBonus: roundedDelta,
              inAppEarnings: 0.0,
              outsideAppEarnings: 0.0,
              totalCompletionAmount: 0.0,
              totalAvailableBalance: roundedDelta,
              lifetimeTotal: roundedDelta,
              payoutRequested: false,
              requestedAmount: 0.0,
              lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
            });
          }
        });
        logger.info(
          `Updated unified wallet for user ${userId} with bonus SAR ${roundedDelta}`
        );
      } catch (walletError) {
        logger.error(`Error updating unified wallet for user ${userId}:`, walletError);
      }

      // 4. Send notification to worker
      await sendAndStoreNotification({
        targetRole: "technician",
        targetId: userId,
        titleEn: "🎉 Bonus Received!",
        titleAr: "🎉 تم استلام المكافأة!",
        titleUr: "🎉 بونس موصول ہوا!",
        bodyEn: `Nice work! You have received a bonus for your ${tier} tier. Check your rewards and wallet for details.`,
        bodyAr: `عمل رائع! لقد حصلت على مكافأة لمستوى ${tier} الخاص بك. تحقق من المكافآت والمحفظة لمعرفة التفاصيل.`,
        bodyUr: `شاباش! آپ نے اپنے ${tier} ٹئیر کے لیے بونس حاصل کیا ہے۔ تفصیلات کے لیے اپنے انعامات اور والیٹ چیک کریں۔`,
        data: {
          category: "bonus",
          tier: tier,
          amount: roundedDelta.toFixed(2),
          bonusPercentage: (bonusPercentage * 100).toString(),
        },
        fcmToken: userData.fcmToken,
        lanCode: userData.lanCode || "en",
      });

      totalBonusesApplied++;
      totalBonusAmount += roundedDelta;

      logger.info(
        `Applied ${tier} bonus of SAR ${roundedDelta.toFixed(2)} to user ${userId} for ${idempotencyValue} in ${targetMonthKey} (full month bonus SAR ${roundedFullBonus.toFixed(2)}, based on ${effectiveJobs} jobs and SAR ${totalInspectionFees.toFixed(2)} Inspection Fees)`
      );
    } catch (userError) {
      logger.error(`Error applying bonus to user ${userId}:`, userError);
    }
  }

  logger.info(
    `Bonus calculation completed (${logLabel}) for ${idempotencyValue}. Bonuses applied: ${totalBonusesApplied}, Total amount: SAR ${totalBonusAmount.toFixed(2)}`
  );
}

// Saudi Arabia is permanently UTC+3 and has never observed DST, so a fixed
// offset is exact. Shifting the epoch by it and then reading UTC fields gives
// the KSA calendar date without depending on the server's own timezone (Cloud
// Functions run in UTC).
const KSA_OFFSET_MS = 3 * 60 * 60 * 1000;

/** KSA calendar month ("YYYY-MM") that an absolute instant falls in. */
function ksaMonthKey(instantMs = Date.now()) {
  const d = new Date(instantMs + KSA_OFFSET_MS);
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, "0")}`;
}

/** The KSA calendar month prior to the one instantMs falls in ("YYYY-MM"). */
function previousKsaMonthKey(instantMs = Date.now()) {
  const d = new Date(instantMs + KSA_OFFSET_MS);
  d.setUTCDate(1);
  d.setUTCMonth(d.getUTCMonth() - 1);
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, "0")}`;
}

/** KSA calendar day ("YYYY-MM-DD") that an absolute instant falls in. */
function ksaDayKey(instantMs) {
  const d = new Date(instantMs + KSA_OFFSET_MS);
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, "0")}-${String(d.getUTCDate()).padStart(2, "0")}`;
}

/** The absolute millis a KSA calendar day spans, end inclusive. */
function ksaDayBounds(dayKey) {
  const [y, m, d] = dayKey.split("-").map(Number);
  const startMs = Date.UTC(y, m - 1, d) - KSA_OFFSET_MS;
  return { startMs, endMs: startMs + 24 * 60 * 60 * 1000 - 1 };
}

/**
 * The KSA day before the one `instantMs` falls in.
 *
 * Derived by stepping back from the start of the current KSA day rather than by
 * subtracting 24h from "now", so it still names the right day when the schedule
 * fires a few seconds or minutes late.
 */
function previousKsaDayKey(instantMs) {
  const { startMs } = ksaDayBounds(ksaDayKey(instantMs));
  return ksaDayKey(startMs - 1);
}

/** KSA calendar hour ("YYYY-MM-DD HH:00") that an absolute instant falls in. */
function ksaHourKey(instantMs) {
  const d = new Date(instantMs + KSA_OFFSET_MS);
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, "0")}-${String(d.getUTCDate()).padStart(2, "0")} ${String(d.getUTCHours()).padStart(2, "0")}:00`;
}

/** The previous hour bounds for instantMs in UTC millis, end inclusive, and its KSA hour key. */
function previousKsaHourBounds(instantMs) {
  const currentHourStartMs = Math.floor(instantMs / (60 * 60 * 1000)) * (60 * 60 * 1000);
  const startMs = currentHourStartMs - 60 * 60 * 1000;
  const endMs = currentHourStartMs - 1;
  const hourKey = ksaHourKey(startMs);
  return { hourKey, startMs, endMs };
}

// Function 1: Reset Tiers Monthly (1st at 00:30 Saudi Arabia Time)
// Resets all worker tier progress at the start of each month
//
// Runs at 00:30, not 00:00, because it zeroes `currentMonthJobs` — which is the
// tier input `applyDailyBonus` reads at 00:00. Reset first and the last day of
// every month would be paid at Bronze (no bonus) for everyone. The old monthly
// bonus wanted the opposite order, since it read the `previousMonth*` snapshot
// this function writes; both schedules moved together when the bonus went daily.
// ============================================
exports.resetMonthlyTiers = onSchedule(
  {
    schedule: "30 0 1 * *", // 1st of every month at 00:30
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

        // Reset tier, job count, and bonus accumulators at user level for the new month.
        // Historical job records remain permanently preserved in the
        // `users/{userId}/monthly_records/{monthKey}` subcollection.
        batch.update(userRef, {
          tier: "Bronze",
          previousMonthTier: userData.tier || "Bronze",
          previousMonthJobs: userData.currentMonthJobs || 0,
          previousMonthRating: userData.rating || 0.0,
          previousMonthReviewCount: userData.reviewCount || 0,
          previousMonthBonus: userData.totalMonthlyBonus || 0,
          currentMonthJobs: 0,
          totalMonthlyBonus: 0,
          bonusAmount: 0,
          lastBonusHour: admin.firestore.FieldValue.delete(),
          lastBonusDay: admin.firestore.FieldValue.delete(),
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
// Function 2: Calculate and Apply Daily Bonuses
// Runs every day at 00:00 Riyadh. Uses the same month-to-date logic as hourly
// and monthly — reads `completedJobs` from the user document, recalculates the
// full bonus, and credits the unpaid delta.
// ============================================
exports.applyDailyBonus = onSchedule(
  {
    schedule: "0 0 * * *", // every day at 00:00
    timeZone: "Asia/Riyadh",
  },
  async (event) => {
    if (BONUS_MODE !== "daily") {
      logger.info(`Daily bonus is disabled (BONUS_MODE=${BONUS_MODE}). Skipping.`);
      return null;
    }

    const dayKey = previousKsaDayKey(Date.now());

    try {
      await calculateAndApplyBonuses({
        idempotencyField: "lastBonusDay",
        idempotencyValue: dayKey,
        logLabel: "daily",
      });
      return null;
    } catch (error) {
      logger.error("Error calculating daily bonuses:", error);
      throw error;
    }
  }
);

// ============================================
// Function 2c: Calculate and Apply Hourly Bonuses
// Runs every hour at minute 0 Riyadh.
// Uses the same month-to-date logic as daily and monthly — reads `completedJobs`
// from the user document, recalculates the full bonus, and credits the unpaid
// delta. Hourly is purely for testing the same flow at higher frequency.
// ============================================
exports.applyHourlyBonus = onSchedule(
  {
    schedule: "0 * * * *", // every hour at minute 0
    timeZone: "Asia/Riyadh",
  },
  async (event) => {
    if (BONUS_MODE !== "hourly") {
      logger.info(`Hourly bonus is disabled (BONUS_MODE=${BONUS_MODE}). Skipping.`);
      return null;
    }

    const { hourKey } = previousKsaHourBounds(Date.now());

    try {
      await calculateAndApplyBonuses({
        idempotencyField: "lastBonusHour",
        idempotencyValue: hourKey,
        logLabel: "hourly",
      });
      return null;
    } catch (error) {
      logger.error("Error calculating hourly bonuses:", error);
      throw error;
    }
  }
);

// ============================================
// Function 2b: Calculate and Apply Monthly Bonuses
// Runs on the 1st of every month at 01:00 Riyadh.
// Uses the same month-to-date logic as daily and hourly — reads `completedJobs`
// from the user document, recalculates the full bonus, and credits the unpaid
// delta. Kept so the bonus mode can be switched back to monthly with a one-line
// change to BONUS_MODE.
// ============================================
exports.applyMonthlyBonus = onSchedule(
  {
    schedule: "0 1 1 * *", // 1st of every month at 01:00
    timeZone: "Asia/Riyadh",
  },
  async (event) => {
    if (BONUS_MODE !== "monthly") {
      logger.info(`Monthly bonus is disabled (BONUS_MODE=${BONUS_MODE}). Skipping.`);
      return null;
    }

    const previousMonthKey = previousKsaMonthKey(Date.now());

    try {
      await calculateAndApplyBonuses({
        idempotencyField: "lastBonusMonth",
        idempotencyValue: previousMonthKey,
        logLabel: "monthly",
        targetMonthKey: previousMonthKey,
      });
      return null;
    } catch (error) {
      logger.error("Error calculating monthly bonuses:", error);
      throw error;
    }
  }
);

// ============================================
// Attach Warranty on Payment Completion
// Triggers when a booking status changes to C and payment is completed
// ============================================
exports.attachWarrantyOnPaymentCompletion = onDocumentUpdated(
  { document: "bookings/{bookingId}", region: FUNCTION_REGION },
  async (event) => {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();
    const bookingId = event.params.bookingId;

    if (!afterData) return;

    // Check if status just changed to C and payment is completed
    const wasPaymentCompletedAndC = beforeData.bookingStatusCode === "C" && beforeData.paymentCompleted === true;
    const isPaymentCompletedAndC = afterData.bookingStatusCode === "C" && afterData.paymentCompleted === true;

    if (!wasPaymentCompletedAndC && isPaymentCompletedAndC) {
      const mode = afterData.completionData?.mode;

      if (mode === 1 && !afterData.warranty) {
        const expiredOn = new Date();
        expiredOn.setDate(expiredOn.getDate() + 7);

        try {
          await admin.firestore().collection("bookings").doc(bookingId).update({
            warranty: {
              id: bookingId,
              claimrequested: false,
              warrantyStatusCode: "A",
              assignedTechnicianId: afterData.agent?.uid || "",
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              expiredOn: admin.firestore.Timestamp.fromDate(expiredOn),
              rejectedTechnicians: [],
            }
          });
          console.log(`[${bookingId}] Warranty attached after payment completion.`);
        } catch (error) {
          console.error(`[${bookingId}] Error attaching warranty:`, error);
        }
      }
    }
  }
);

// ============================================
// Function 3: Update Tier Stats on Job Completion
// Triggers when a booking status changes to completed
// ============================================
exports.updateTierStatsOnJobComplete = onDocumentUpdated(
  { document: "bookings/{jobId}", region: FUNCTION_REGION },
  async (event) => {
    const before = event.data?.before?.data() || {};
    const after = event.data?.after?.data();

    if (!after) return null;

    const beforeCode = (before.bookingStatusCode || "").toUpperCase();
    const afterCode = (after.bookingStatusCode || "").toUpperCase();

    // Only proceed if status changed to completed (C)
    if (beforeCode === "C" || afterCode !== "C") {
      return null;
    }

    if (after.tierStatsUpdatedAt) {
      logger.info(`Tier stats already updated for booking ${event.params.jobId}`);
      return null;
    }

    const workerId = after.agent?.uid || after.workerId || after.technicianId;
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
      const totalRating = userData.rating || 0;
      const reviewCount = userData.reviewCount || 0;
      const currentTier = userData.tier || "Bronze";

      const newJobCount = currentJobs + 1;

      const averageRating = reviewCount > 0 ? parseFloat((totalRating / reviewCount).toFixed(2)) : 5.0;

      // Same ladder the nightly bonus pays on — see `resolveTier`. These were
      // two separate copies of the thresholds, so editing one moved the badge
      // a worker sees without moving the tier they actually get paid for.
      const { tier: newTier } = resolveTier(newJobCount, averageRating);

      // Build the completed-job record for bonus calculation. Stored in
      // subcollection users/{workerId}/monthly_records/{monthKey} so the
      // root user profile remains small and light.
      const inspectionFee = Number(after.completionData?.inspectionFee) || 0;
      let generalPrice =
        Number(after.completionData?.generalServicePrice) ||
        Number(after.service?.price) ||
        0;

      if (generalPrice <= 0 && inspectionFee <= 0 && after.service?.id) {
        try {
          const serviceDoc = await db.collection("services").doc(after.service.id).get();
          if (serviceDoc.exists) {
            generalPrice = Number(serviceDoc.data()?.price) || 0;
          }
        } catch (err) {
          logger.warn(`Could not fetch general service price for ${after.service.id}:`, err);
        }
      }

      const discountPercentage = Number(after.service?.discountPercentage) || 0;

      const completedJobEntry = {
        bookingId: event.params.jobId,
        inspectionFee: inspectionFee,
        generalPrice: generalPrice,
        discountPercentage: discountPercentage,
        completedDate: admin.firestore.Timestamp.now(),
      };

      const monthKey = ksaMonthKey(Date.now());
      const monthRecordRef = userRef.collection("monthly_records").doc(monthKey);

      const batch = db.batch();
      batch.update(userRef, {
        currentMonthJobs: admin.firestore.FieldValue.increment(1),
        tier: newTier,
      });
      batch.set(
        monthRecordRef,
        {
          monthKey: monthKey,
          workerId: workerId,
          jobsCount: admin.firestore.FieldValue.increment(1),
          completedJobs: admin.firestore.FieldValue.arrayUnion(completedJobEntry),
          tier: newTier,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      batch.update(event.data.after.ref, {
        tierStatsUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      await batch.commit();

      // Send notification if tier upgraded
      if (newTier !== currentTier) {
        const tierOrder = { Bronze: 0, Silver: 1, Gold: 2, Platinum: 3 };
        if (tierOrder[newTier] > tierOrder[currentTier]) {
          const fcmToken = userData.fcmToken;
          const lanCode = userData.lanCode || "en";

          // Not gated on the token - the technician app lists what this stores.
          {
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
              titleUr: `🎊 ٹئیر ${newTier} میں اپ گریڈ ہو گیا!`,
              bodyEn: `Congratulations! You've been upgraded to ${newTier} tier! You now earn ${bonusPercentages[newTier] || "0%"
                } bonus on your monthly earnings. Keep up the great work!`,
              bodyAr: `تهانينا! تمت ترقيتك إلى مستوى ${newTier}! أنت الآن تكسب ${bonusPercentages[newTier] || "0%"
                } مكافأة على أرباحك الشهرية. استمر في العمل الرائع!`,
              bodyUr: `مبارک ہو! آپ کو ${newTier} ٹئیر میں اپ گریڈ کر دیا گیا ہے! اب آپ اپنی ماہانہ کمائی پر ${bonusPercentages[newTier] || "0%"
                } بونس کماتے ہیں۔ اسی طرح بہترین کام جاری رکھیں!`,
              data: {
                category: "tier_upgrade",
                oldTier: currentTier,
                newTier: newTier,
                jobs: newJobCount.toString(),
                rating: averageRating.toFixed(2),
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
        `✅ Updated stats for user ${workerId} (${serviceName}): ${newJobCount} jobs, ${averageRating.toFixed(
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
  { document: "bookings/{bookingId}", region: FUNCTION_REGION },
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

    // Skip if the status is not S
    if (afterStatusCode !== "S") {
      console.log(
        `[${bookingId}] Skipping warranty notification - status is not S (current: ${afterStatusCode})`
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

      // A missing token only means there is no push to send:
      // sendAndStoreNotification still writes the in-app record.
      if (!technicianFcmToken || technicianFcmToken.trim() === "") {
        console.log(
          `[${bookingId}] Technician ${afterTechnicianId} has no valid FCM token; storing notification without a push`
        );
      }

      // Get booking details
      const serviceName = afterData.service?.name || "Service";
      const serviceNameAr = afterData.service?.name_ar || serviceName;
      const serviceNameUr =
        afterData.service?.name_ur || serviceNameAr || serviceName;
      const customerName = afterData.customer?.name || "Customer";
      const customerId = afterData.customer?.uid || "";

      // Send notification
      await sendAndStoreNotification({
        targetRole: "technician",
        targetId: afterTechnicianId,
        titleEn: "Warranty Repair Assigned",
        titleAr: "تم تعيينك لإصلاح ضمان",
        titleUr: "وارنٹی کی مرمت تفویض کی گئی",
        bodyEn: `You have been assigned to a warranty repair for ${serviceName}. Customer: ${customerName}. Please review and accept.`,
        bodyAr: `تم تعيينك لإصلاح ضمان لـ ${serviceNameAr}. العميل: ${customerName}. يرجى المراجعة والقبول.`,
        bodyUr: `آپ کو ${serviceNameUr} کی وارنٹی مرمت تفویض کی گئی ہے۔ صارف: ${customerName}۔ براہ کرم جائزہ لے کر قبول کریں۔`,
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
  { document: "payouts/{payoutId}", region: FUNCTION_REGION },
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
    let titleEn, titleAr, titleUr, bodyEn, bodyAr, bodyUr;

    switch (type) {
      case "earnings":
        titleEn = "New Earnings Payout Request";
        titleAr = "طلب صرف أرباح جديد";
        titleUr = "کمائی کی ادائیگی کی نئی درخواست";
        bodyEn = `${technicianName} has requested an earnings payout of ${money(amount, "en")}.`;
        bodyAr = `طلب ${technicianName} صرف أرباح بقيمة ${money(amount, "ar")}.`;
        bodyUr = `${technicianName} نے ${money(amount, "ur")} کی کمائی کی ادائیگی کی درخواست کی ہے۔`;
        break;
      case "bonus":
        titleEn = "New Bonus Payout Request";
        titleAr = "طلب صرف مكافأة جديد";
        titleUr = "بونس کی ادائیگی کی نئی درخواست";
        bodyEn = `${technicianName} has requested a bonus payout of ${money(amount, "en")}.`;
        bodyAr = `طلب ${technicianName} صرف مكافأة بقيمة ${money(amount, "ar")}.`;
        bodyUr = `${technicianName} نے ${money(amount, "ur")} کے بونس کی ادائیگی کی درخواست کی ہے۔`;
        break;
      default:
        titleEn = "New Payout Request";
        titleAr = "طلب صرف جديد";
        titleUr = "ادائیگی کی نئی درخواست";
        bodyEn = `${technicianName} has requested a payout of ${money(amount, "en")}.`;
        bodyAr = `طلب ${technicianName} صرف بقيمة ${money(amount, "ar")}.`;
        bodyUr = `${technicianName} نے ${money(amount, "ur")} کی ادائیگی کی درخواست کی ہے۔`;
    }

    // Fetch all admin users
    try {
      const adminUsersDocs = await getAllAdminUsers();

      if (!adminUsersDocs || adminUsersDocs.length === 0) {
        console.log(`[${payoutId}] No admin users found`);
        return;
      }

      // Send notification to each admin
      for (const adminDoc of adminUsersDocs) {
        const adminData = adminDoc.data();
        const adminFcmToken = adminData?.fcmToken;
        const adminLanCode = adminData?.lanCode || "en";

        // A missing token only means there is no push to send:
        // sendAndStoreNotification still writes the in-app record.
        if (!adminFcmToken || adminFcmToken.trim() === "") {
          console.log(
            `[${payoutId}] Admin ${adminDoc.id} has no valid FCM token; storing notification without a push`
          );
        }

        await sendAndStoreNotification({
          targetRole: "admin",
          targetId: adminDoc.id,
          titleEn,
          titleAr,
          titleUr,
          bodyEn,
          bodyAr,
          bodyUr,
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
// Notify Admins on New Unified Payout Request
// ============================================

exports.notifyAdminsOnUnifiedPayoutRequest = onDocumentCreated(
  { document: "unified_payout_requests/{requestId}", region: FUNCTION_REGION },
  async (event) => {
    const requestId = event.params.requestId;
    const requestData = event.data?.data();

    if (!requestData) {
      console.log(`[${requestId}] No unified payout request data found`);
      return;
    }

    const workerId = requestData.workerId;
    const workerName = requestData.workerName || "Technician";
    const totalAmount = requestData.totalAmount || "0";
    const status = requestData.status;

    // Only notify on pending requests
    if (status !== "P") {
      console.log(`[${requestId}] Payout status is not pending, skipping...`);
      return;
    }

    console.log(
      `[${requestId}] New unified payout request detected for worker ${workerId}, amount: ${totalAmount}`
    );

    const titleEn = "New Payout Request";
    const titleAr = "طلب صرف جديد";
    const titleUr = "نئی پے آؤٹ کی درخواست";
    const bodyEn = `${workerName} has requested a unified payout of ${money(totalAmount, "en")}. Please review the request.`;
    const bodyAr = `طلب ${workerName} صرف مجمع بقيمة ${money(totalAmount, "ar")}. يرجى مراجعة الطلب.`;
    const bodyUr = `${workerName} نے ${money(totalAmount, "ur")} کی یونیفائیڈ پے آؤٹ کی درخواست کی ہے۔ براہ کرم درخواست کا جائزہ لیں۔`;

    // Fetch all admin users
    try {
      const adminUsersDocs = await getAllAdminUsers();

      if (!adminUsersDocs || adminUsersDocs.length === 0) {
        console.log(`[${requestId}] No admin users found`);
        return;
      }

      // Send notification to each admin
      for (const adminDoc of adminUsersDocs) {
        const adminData = adminDoc.data();
        const adminFcmToken = adminData?.fcmToken;
        const adminLanCode = adminData?.lanCode || "en";

        // A missing token only means there is no push to send:
        // sendAndStoreNotification still writes the in-app record.
        if (!adminFcmToken || adminFcmToken.trim() === "") {
          console.log(
            `[${requestId}] Admin ${adminDoc.id} has no valid FCM token; storing notification without a push`
          );
        }

        await sendAndStoreNotification({
          targetRole: "admin",
          targetId: adminDoc.id,
          titleEn,
          titleAr,
          titleUr,
          bodyEn,
          bodyAr,
          bodyUr,
          data: {
            targetRole: "admin",
            category: "unified_payout",
            requestId,
            workerId,
            technicianName: workerName,
            amount: totalAmount.toString(),
            type: "unified",
            isAdmin: "true",
          },
          fcmToken: adminFcmToken,
          lanCode: adminLanCode,
        });
      }

      console.log(
        `[${requestId}] ✅ Unified payout request notifications sent to admins`
      );
    } catch (error) {
      console.error(
        `[${requestId}] Error sending unified payout request notifications:`,
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
  { document: "tipping/{agentId}", region: FUNCTION_REGION },
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

      if (!adminUsersDocs || adminUsersDocs.length === 0) {
        console.log(`[${agentId}] No admin users found`);
        return;
      }

      // Send notification to each admin
      for (const adminDoc of adminUsersDocs) {
        const adminData = adminDoc.data();
        const adminFcmToken = adminData?.fcmToken;
        const adminLanCode = adminData?.lanCode || "en";

        // A missing token only means there is no push to send:
        // sendAndStoreNotification still writes the in-app record.
        if (!adminFcmToken || adminFcmToken.trim() === "") {
          console.log(
            `[${agentId}] Admin ${adminDoc.id} has no valid FCM token; storing notification without a push`
          );
        }

        await sendAndStoreNotification({
          targetRole: "admin",
          targetId: adminDoc.id,
          titleEn: "New Tips Payout Request",
          titleAr: "طلب صرف إكراميات جديد",
          titleUr: "ٹپس کی ادائیگی کی نئی درخواست",
          bodyEn: `${technicianName} has requested a tips payout of ${money(cardTips, "en")}.`,
          bodyAr: `طلب ${technicianName} صرف إكراميات بقيمة ${money(cardTips, "ar")}.`,
          bodyUr: `${technicianName} نے ${money(cardTips, "ur")} کی ٹپس ادائیگی کی درخواست کی ہے۔`,
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
  { document: "tipping/{agentId}", region: FUNCTION_REGION },
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

      // A missing token only means there is no push to send:
      // sendAndStoreNotification still writes the in-app record.
      if (!technicianFcmToken || technicianFcmToken.trim() === "") {
        console.log(`[${agentId}] Technician has no valid FCM token; storing notification without a push`);
      }

      // Send notification to technician
      try {
        await sendAndStoreNotification({
          targetRole: "technician",
          targetId: agentId,
          titleEn: "Tips Payout Completed",
          titleAr: "تم صرف الإكراميات",
          titleUr: "ٹپس کی ادائیگی مکمل",
          bodyEn: `Your tips payout of ${money(beforeCardTip, "en")} has been processed and sent to your account.`,
          bodyAr: `تم معالجة صرف إكرامياتك بقيمة ${money(beforeCardTip, "ar")} وإرسالها إلى حسابك.`,
          bodyUr: `آپ کی ${money(beforeCardTip, "ur")} کی ٹپس ادائیگی مکمل ہو کر آپ کے اکاؤنٹ میں بھیج دی گئی ہے۔`,
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
// Notify Technician on Unified Payout Approval/Rejection
// ============================================
exports.notifyTechnicianOnUnifiedPayoutStatusChange = onDocumentWritten(
  { document: "unified_payout_requests/{requestId}", region: FUNCTION_REGION },
  async (event) => {
    const requestId = event.params.requestId;
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();

    if (!afterData) {
      console.log(`[${requestId}] Document deleted, skipping...`);
      return;
    }

    const beforeStatus = beforeData?.status;
    const afterStatus = afterData.status;

    // Check if status changed to approved (A) or rejected (R)
    if (beforeStatus === afterStatus) {
      return;
    }

    if (afterStatus !== "A" && afterStatus !== "R") {
      return;
    }

    const workerId = afterData.workerId;
    const totalAmount = afterData.totalAmount || "0";
    const rejectionReason = afterData.rejectionReason || "";
    const transactionId = afterData.transactionId || "";

    console.log(
      `[${requestId}] Unified payout status changed to ${afterStatus} for worker ${workerId}`
    );

    // Fetch technician data
    let technicianData;
    try {
      const technicianDoc = await admin
        .firestore()
        .collection("users")
        .doc(workerId)
        .get();

      if (!technicianDoc.exists) {
        console.log(`[${requestId}] Technician document not found`);
        return;
      }

      technicianData = technicianDoc.data();
    } catch (error) {
      console.error(`[${requestId}] Error fetching technician data:`, error);
      return;
    }

    const technicianFcmToken = technicianData?.fcmToken;
    const technicianLanCode = technicianData?.lanCode || "en";

    // A missing token only means there is no push to send:
    // sendAndStoreNotification still writes the in-app record.
    if (!technicianFcmToken || technicianFcmToken.trim() === "") {
      console.log(`[${requestId}] Technician has no valid FCM token; storing notification without a push`);
    }

    let titleEn, titleAr, titleUr, bodyEn, bodyAr, bodyUr;

    if (afterStatus === "A") {
      // Approved
      titleEn = "Payout Request Approved";
      titleAr = "تمت الموافقة على طلب الصرف";
      titleUr = "پے آؤٹ کی درخواست منظور ہو گئی";
      bodyEn = `Your payout request of ${money(totalAmount, "en")} has been approved.`;
      bodyAr = `تمت الموافقة على طلب الصرف الخاص بك بقيمة ${money(totalAmount, "ar")}.`;
      bodyUr = `آپ کی ${money(totalAmount, "ur")} کی پے آؤٹ کی درخواست منظور کر لی گئی ہے۔`;
    } else if (afterStatus === "R") {
      // Rejected
      titleEn = "Payout Request Rejected";
      titleAr = "تم رفض طلب الصرف";
      titleUr = "پے آؤٹ کی درخواست مسترد کر دی گئی";
      bodyEn = `Your payout request of ${money(totalAmount, "en")} has been rejected.`;
      bodyAr = `تم رفض طلب الصرف الخاص بك بقيمة ${money(totalAmount, "ar")}.`;
      bodyUr = `آپ کی ${money(totalAmount, "ur")} کی پے آؤٹ کی درخواست مسترد کر دی گئی ہے۔`;
    }

    // Send notification to technician
    try {
      await sendAndStoreNotification({
        targetRole: "technician",
        targetId: workerId,
        titleEn,
        titleAr,
        titleUr,
        bodyEn,
        bodyAr,
        bodyUr,
        data: {
          targetRole: "technician",
          category: "unified_payout",
          requestId,
          amount: totalAmount.toString(),
          status: afterStatus,
          transactionId: transactionId || "",
          rejectionReason: rejectionReason || "",
          isAdmin: "false",
        },
        fcmToken: technicianFcmToken,
        lanCode: technicianLanCode,
      });

      console.log(`[${requestId}] Status notification sent to technician ${workerId}`);
    } catch (error) {
      console.error(`[${requestId}] Error sending notification:`, error);
    }
  }
);

// ============================================
// Notify Technician on Payout Approval/Rejection
// ============================================
exports.notifyTechnicianOnPayoutStatusChange = onDocumentWritten(
  { document: "payouts/{payoutId}", region: FUNCTION_REGION },
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

    // A missing token only means there is no push to send:
    // sendAndStoreNotification still writes the in-app record.
    if (!technicianFcmToken || technicianFcmToken.trim() === "") {
      console.log(`[${payoutId}] Technician has no valid FCM token; storing notification without a push`);
    }

    // Determine notification content based on status and type
    let titleEn, titleAr, titleUr, bodyEn, bodyAr, bodyUr;

    // Get type-specific labels
    const typeLabels = {
      earnings: { en: "earnings", ar: "الأرباح", ur: "کمائی" },
      bonus: { en: "bonus", ar: "المكافأة", ur: "بونس" },
      tips: { en: "tips", ar: "الإكراميات", ur: "ٹپس" },
    };

    const typeLabel = typeLabels[type] || typeLabels.earnings;

    if (afterStatus === "C") {
      // Approved
      titleEn = "Payout Request Approved";
      titleAr = "تمت الموافقة على طلب الصرف";
      titleUr = "ادائیگی کی درخواست منظور ہو گئی";
      bodyEn = `Your ${typeLabel.en} payout request of ${money(amount, "en")} has been approved. Transaction number: ${transactionNumber}`;
      bodyAr = `تمت الموافقة على طلب صرف ${typeLabel.ar} الخاص بك بقيمة ${money(amount, "ar")}. رقم المعاملة: ${transactionNumber}`;
      bodyUr = `آپ کی ${money(amount, "ur")} کی ${typeLabel.ur} ادائیگی کی درخواست منظور کر لی گئی ہے۔ ٹرانزیکشن نمبر: ${transactionNumber}`;
    } else if (afterStatus === "R") {
      // Rejected
      titleEn = "Payout Request Rejected";
      titleAr = "تم رفض طلب الصرف";
      titleUr = "ادائیگی کی درخواست مسترد";
      bodyEn = `Your ${typeLabel.en
        } payout request of ${money(amount, "en")} has been rejected.${rejectionReason ? ` Reason: ${rejectionReason}` : ""
        }`;
      bodyAr = `تم رفض طلب صرف ${typeLabel.ar} الخاص بك بقيمة ${money(amount, "ar")}.${rejectionReason ? ` السبب: ${rejectionReason}` : ""
        }`;
      bodyUr = `آپ کی ${money(amount, "ur")} کی ${typeLabel.ur} ادائیگی کی درخواست مسترد کر دی گئی ہے۔${rejectionReason ? ` وجہ: ${rejectionReason}` : ""
        }`;
    }

    // Send notification to technician
    try {
      await sendAndStoreNotification({
        targetRole: "technician",
        targetId: userId,
        titleEn,
        titleAr,
        titleUr,
        bodyEn,
        bodyAr,
        bodyUr,
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
/**
 * Haversine formula to calculate distance between two points on Earth
 */
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

/**
 * Ray-casting point-in-polygon algorithm to check if point (lat, lon) is inside polygon
 */
function isPointInPolygon(lat, lon, polygon) {
  if (!polygon || polygon.length < 3) return false;

  let inside = false;
  let j = polygon.length - 1;

  for (let i = 0; i < polygon.length; i++) {
    const xi = parseFloat(polygon[i].lat);
    const yi = parseFloat(polygon[i].lng || polygon[i].lon || polygon[i].longitude);
    const xj = parseFloat(polygon[j].lat);
    const yj = parseFloat(polygon[j].lng || polygon[j].lon || polygon[j].longitude);

    const intersect =
      ((yi > lon) !== (yj > lon)) &&
      (lat < (xj - xi) * (lon - yi) / (yj - yi) + xi);

    if (intersect) inside = !inside;
    j = i;
  }

  return inside;
}

/**
 * Check if a location (lat, lon) falls inside any of the service location zones
 */
function isAddressInServiceZones(lat, lon, serviceLocations) {
  for (const zone of serviceLocations) {
    const polygon = zone.polygon;
    if (!polygon || polygon.length === 0) continue;

    if (isPointInPolygon(lat, lon, polygon)) {
      return true;
    }
  }
  return false;
}
exports.notifyAdminsOnNewTechnicianRegistration = onDocumentWritten(
  { document: "users/{userId}", region: FUNCTION_REGION },
  async (event) => {
    const beforeData = event.data?.before?.data() || {};
    const afterData = event.data?.after?.data();

    if (!afterData) return null; // Document was deleted
    const userId = event.params.userId;

    // Only notify if the user is a technician
    if (afterData.role !== "technician") {
      return null;
    }

    // Check if registration was just completed
    const wasCompleted = beforeData.isRegistrationComplete === true;
    const isNowCompleted = afterData.isRegistrationComplete === true;

    // If it was already completed, or is still not completed, skip.
    // (This triggers both on initial creation with isRegistrationComplete=true
    // AND on update when isRegistrationComplete changes from false to true)
    if (wasCompleted || !isNowCompleted) {
      return null;
    }

    const techName = afterData.name || "New Technician";

    try {
      const adminUsersDocs = await getAllAdminUsers();

      const adminTokens = toNotificationRecipients(
        adminUsersDocs.filter((doc) => doc.data().accessLevel !== 2) // Exclude customer service admins
      );

      if (adminTokens.length === 0) {
        console.log(`[${userId}] No admins found for registration notification.`);
        return null;
      }

      await Promise.allSettled(adminTokens.map(async ({ uid, token, lanCode }) => {
        await sendAndStoreNotification({
          targetRole: "admin",
          targetId: uid,
          titleEn: "New Technician Registered",
          titleAr: "فني جديد مسجل",
          titleUr: "نیا ٹیکنیشن رجسٹرڈ ہو گیا",
          bodyEn: `A new technician "${techName}" has registered and is pending review.`,
          bodyAr: `تم تسجيل فني جديد باسم "${techName}" وهو بانتظار المراجعة.`,
          bodyUr: `ایک نیا ٹیکنیشن "${techName}" رجسٹر ہوا ہے اور جائزے کا منتظر ہے۔`,
          data: {
            targetRole: "admin",
            category: "technician_registration",
            technicianId: userId,
            technicianName: techName,
            isAdmin: "true",
            requestId: userId,
          },
          fcmToken: token,
          lanCode: lanCode,
        });
      }));
      console.log(`[${userId}] Admin notifications sent for new technician registration.`);
    } catch (error) {
      console.error(`[${userId}] Error sending admin notifications for technician registration:`, error);
    }

    return null;
  }
);

exports.notifyCustomerWhenTechnicianIsNearby = onDocumentUpdated(
  { document: "users/{userId}", region: FUNCTION_REGION },
  async (event) => {
    const beforeData = event.data?.before?.data() || {};
    const afterData = event.data?.after?.data() || {};
    const userId = event.params.userId;

    const beforeLoc = beforeData.liveLocation;
    const afterLoc = afterData.liveLocation;

    if (!afterLoc || !afterLoc.latitude || !afterLoc.longitude) {
      return null;
    }

    // Only proceed if the location changed
    if (beforeLoc && beforeLoc.latitude === afterLoc.latitude && beforeLoc.longitude === afterLoc.longitude) {
      return null;
    }

    const techLat = parseFloat(afterLoc.latitude);
    const techLon = parseFloat(afterLoc.longitude);

    if (isNaN(techLat) || isNaN(techLon)) {
      return null;
    }

    try {
      // Find active bookings assigned to this technician that are currently started (on their way)
      const activeBookingsSnapshot = await db.collection("bookings")
        .where("agent.uid", "==", userId)
        .where("bookingStatusCode", "==", "A")
        .where("isStarted", "==", true)
        .get();

      if (activeBookingsSnapshot.empty) {
        return null;
      }

      for (const bookingDoc of activeBookingsSnapshot.docs) {
        const booking = bookingDoc.data();
        const bookingId = bookingDoc.id;

        // Skip if nearby notification is already sent for this booking
        if (booking.isNearbySent === true) {
          continue;
        }

        const addresses = booking.customer?.addresses || [];
        const selectedAddress = addresses.find(a => a.isSelected === true) || (addresses.length > 0 ? addresses[0] : null);

        const custLat = parseFloat(selectedAddress?.lat || booking.location?.lat || booking.lat || booking.latitude);
        const custLon = parseFloat(selectedAddress?.lon || booking.location?.lon || booking.lon || booking.longitude);

        if (isNaN(custLat) || isNaN(custLon)) {
          continue;
        }

        // Calculate distance in kilometers
        const distance = calculateDistance(custLat, custLon, techLat, techLon);

        // 50 meters is 0.05 km
        if (distance <= 0.05) {
          console.log(`[${bookingId}] Technician ${userId} is within ${distance * 1000} meters of service location! Sending nearby notification.`);

          const customer = booking.customer;
          const customerId = customer?.uid;

          if (!customerId) continue;

          // Fetch customer's FCM token and language preference
          const customerDoc = await db.collection("customers").doc(customerId).get();
          if (!customerDoc.exists) continue;

          const customerData = customerDoc.data();
          const fcmToken = customerData?.fcmToken;
          const lanCode = customerData?.lanCode || "en";

          // Store even without a token; only the push depends on it.
          if (!fcmToken || fcmToken.trim() === "") {
            console.log(`[${bookingId}] Customer has no valid FCM token; storing notification without a push.`);
          }

          // Mark as sent first to prevent duplicate notifications from fast concurrent updates
          await db.collection("bookings").doc(bookingId).update({
            isNearbySent: true,
            updatedAt: FieldValue.serverTimestamp()
          });

          await sendAndStoreNotification({
            targetRole: "customer",
            targetId: customerId,
            titleEn: "Technician is nearby",
            titleAr: "الفني بالقرب منك",
            titleUr: "ٹیکنیشن قریب ہی ہے",
            bodyEn: "Technician is nearby, estimated to arrive in 5 minutes.",
            bodyAr: "الفني بالقرب منك، ومن المتوقع وصوله خلال 5 دقائق.",
            bodyUr: "ٹیکنیشن قریب ہی ہے، 5 منٹ میں پہنچنے کی امید ہے۔",
            data: {
              bookingId: bookingId,
              category: "tracking",
              type: "nearby"
            },
            fcmToken: fcmToken,
            lanCode: lanCode
          });
        }
      }
    } catch (e) {
      console.error(`Error in notifyCustomerWhenTechnicianIsNearby for user ${userId}:`, e);
    }
    return null;
  }
);

// notifyCustomerOnBroadcastAccepted was removed here.
//
// It fired on the same job_offers status transition to "accepted_by_technician"
// as onManualJobOfferUpdated in src/triggers/bookingTriggers.js, which already
// notifies the customer. It never actually delivered: it looked the customer up
// in "users", but customers live in "customers", so every invocation returned
// early. Repairing the collection would only have produced two notifications for
// one acceptance.

// Helper for distance calculation
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

// Helper to safely extract customer coordinates from a request document
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

// Helper to safely extract customer address from a request document
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

// Helper to safely extract technician coordinates from a user document
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

// 1. Trigger when a manual booking request is created

exports.assignNewBookingId_bookings = onDocumentCreated({ document: "bookings/{docId}", region: FUNCTION_REGION }, async (event) => {
  if (!event.data) return null;
  const bookingTriggers = require('./src/triggers/bookingTriggers');
  return bookingTriggers.assignNewBookingIdHelper(event.data.ref, event.data.data());
});

exports.assignNewBookingId_jobRequests = onDocumentCreated({ document: "job_requests/{docId}", region: FUNCTION_REGION }, async (event) => {
  if (!event.data) return null;
  const bookingTriggers = require('./src/triggers/bookingTriggers');
  return bookingTriggers.assignNewBookingIdHelper(event.data.ref, event.data.data());
});

exports.assignNewBookingId_bookingRequest = onDocumentCreated({ document: "booking_request/{docId}", region: FUNCTION_REGION }, async (event) => {
  if (!event.data) return null;
  const bookingTriggers = require('./src/triggers/bookingTriggers');
  return bookingTriggers.assignNewBookingIdHelper(event.data.ref, event.data.data());
});

exports.assignNewBookingId_autoAssignment = onDocumentCreated({ document: "auto-assignment_requests/{docId}", region: FUNCTION_REGION }, async (event) => {
  if (!event.data) return null;
  const bookingTriggers = require('./src/triggers/bookingTriggers');
  return bookingTriggers.assignNewBookingIdHelper(event.data.ref, event.data.data());
});

exports.updateTechnicianRatingOnReview = onDocumentWritten(
  { document: "bookings/{bookingId}", region: FUNCTION_REGION },
  async (event) => {
    const afterData = event.data.after ? event.data.after.data() : null;
    const beforeData = event.data.before ? event.data.before.data() : null;

    const workerId = afterData?.agent?.uid;
    if (!workerId) return null;

    const newRating = afterData?.review?.rating;
    const oldRating = beforeData?.review?.rating;

    if (newRating === oldRating) return null; // No change in rating

    const userRef = db.collection("users").doc(workerId);

    return db.runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);
      if (!userDoc.exists) return;

      const userData = userDoc.data();
      let currentRatingCount = userData.reviewCount || 0;
      let totalRating = userData.rating || 0.0;

      if (typeof oldRating !== "number" && typeof newRating === "number") {
        // New review
        currentRatingCount += 1;
        totalRating += newRating;
      } else if (typeof oldRating === "number" && typeof newRating === "number") {
        // Updated review
        totalRating = totalRating - oldRating + newRating;
      } else if (typeof oldRating === "number" && typeof newRating !== "number") {
        // Deleted review
        currentRatingCount = Math.max(0, currentRatingCount - 1);
        totalRating -= oldRating;
      }

      transaction.update(userRef, {
        rating: totalRating,
        reviewCount: currentRatingCount,
      });
      console.log(`Updated technician ${workerId} rating sum to ${totalRating} (${currentRatingCount} reviews)`);
    });
  }
);

// notifyOnWarrantyStatusChange used to live here: a second trigger on the same
// document whose only branch was the technician-cancelled S -> R transition. It
// notified the customer and every admin, and so did case 7 ("technician
// rejected") of notifyOnWarrantyRequestStatusChange above, which fires on the
// same write because cancelling grows warranty.rejectedTechnicians. One
// cancellation therefore produced two differently-worded notifications per
// recipient, which no dedup key could collapse. Case 7 is the one kept: it
// covers the same audience and its admin copy carries the rejection reason.

// Cleanup issueMedia folder once a month
// Monthly at 00:00 Riyadh — every scheduled job in this codebase runs on the
// Saudi calendar so "the 1st" means the same day everywhere.
exports.cleanupIssueMedia = onSchedule(
  { schedule: "0 0 1 * *", timeZone: "Asia/Riyadh" },
  async (event) => {
  console.log("Starting monthly cleanup of issueMedia folder...");
  try {
    const bucket = admin.storage().bucket();
    const [files] = await bucket.getFiles({ prefix: 'issueMedia/' });

    const oneMonthAgo = new Date();
    oneMonthAgo.setMonth(oneMonthAgo.getMonth() - 1);

    const deletePromises = [];
    let count = 0;

    for (const file of files) {
      const [metadata] = await file.getMetadata();
      const timeCreated = new Date(metadata.timeCreated);

      if (timeCreated < oneMonthAgo) {
        deletePromises.push(file.delete().catch(e => console.error(`Failed to delete ${file.name}:`, e)));
        count++;
      }
    }

    await Promise.all(deletePromises);
    console.log(`Successfully cleaned up ${count} files from issueMedia folder.`);
  } catch (error) {
    console.error("Error cleaning up issueMedia folder:", error);
  }
});
// Helper to delete chat from Realtime Database
async function deleteChatFromRTDB(chatId) {
  if (!chatId) return;
  try {
    const rtdb = getRtdb();
    const chatSnap = await rtdb.ref(`chats/${chatId}`).get();
    if (chatSnap.exists()) {
      const chatData = chatSnap.val();
      const participants = chatData.participants || {};

      await rtdb.ref(`messages/${chatId}`).remove();

      // Delete userChats entries BEFORE deleting the main chat so participant rules still pass
      for (const userId of participantUids(participants)) {
        await rtdb.ref(`userChats/${userId}/${chatId}`).remove();
      }

      await rtdb.ref(`chats/${chatId}`).remove();
      console.log(`[${chatId}] Chat successfully deleted from RTDB.`);
    } else {
      console.log(`[${chatId}] Chat not found in RTDB, skipped deletion.`);
    }
  } catch (error) {
    console.error(`[${chatId}] Error deleting chat from RTDB:`, error);
  }
}

// 1. Delete inspection-only chatrooms on booking completion
exports.chatCleanupOnCompletion = onDocumentUpdated(
  { document: "bookings/{bookingId}", region: FUNCTION_REGION },
  async (event) => {
    const beforeData = event.data?.before?.data() || {};
    const afterData = event.data?.after?.data() || {};
    const bookingId = event.params.bookingId;

    // Proceed only if status JUST changed to 'C'
    if (beforeData.bookingStatusCode !== "C" && afterData.bookingStatusCode === "C") {
      const mode = afterData.completionData?.mode;
      const chatId = afterData.chatroomId;

      if (mode === 0 && chatId) {
        console.log(`[${bookingId}] Booking completed as 'inspection only'. Cleaning up chatroom ${chatId}...`);

        await deleteChatFromRTDB(chatId);

        // Remove chatroomId from booking
        await admin.firestore().collection("bookings").doc(bookingId).update({
          chatroomId: FieldValue.delete()
        });
      }
    }
  }
);

// 2. Scheduled deletion for full service chats after 14 days
exports.scheduledChatCleanup = onSchedule(
  { schedule: "0 0 * * 0", timeZone: "Asia/Riyadh" },
  async (event) => {
  console.log("Starting weekly cleanup of chatrooms for full service bookings...");
  try {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - 14); // 14 days ago
    const cutoffTimestamp = admin.firestore.Timestamp.fromDate(cutoffDate);

    // Find completed bookings with a chatroomId and a completedAt older than 14 days
    const snapshot = await admin.firestore().collection("bookings")
      .where("bookingStatusCode", "==", "C")
      .where("completedAt", "<=", cutoffTimestamp)
      .get();

    let count = 0;
    const batch = admin.firestore().batch();
    let batchCount = 0;

    for (const doc of snapshot.docs) {
      const data = doc.data();
      const chatId = data.chatroomId;

      // Mode !== 0 (full service) and has chat
      if (chatId && data.completionData?.mode !== 0) {
        await deleteChatFromRTDB(chatId);

        // Remove from firestore document
        batch.update(doc.ref, { chatroomId: FieldValue.delete() });
        count++;
        batchCount++;

        if (batchCount >= 500) {
          await batch.commit();
          batchCount = 0;
          const newBatch = admin.firestore().batch();
          Object.assign(batch, newBatch);
        }
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    console.log(`Successfully cleaned up ${count} chatrooms for old full service bookings.`);
  } catch (error) {
    console.error("Error in scheduledChatCleanup:", error);
  }
});

exports.notifyTechnicianOnPaymentVerificationPending = onDocumentWritten(
  { document: "bookings/{bookingId}", region: FUNCTION_REGION },
  async (event) => {
    const bookingId = event.params.bookingId;
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();

    if (!afterData) {
      console.log(`[${bookingId}] Document deleted, skipping...`);
      return;
    }

    const wasVP = beforeData?.bookingStatusCode === "VP";
    const isVP = afterData.bookingStatusCode === "VP";

    if (!isVP || wasVP) {
      return;
    }

    console.log(`[${bookingId}] Booking status is VP, proceeding with verification notification`);

    const agent = afterData.agent;
    if (!agent || !agent.uid) {
      console.log(`[${bookingId}] No agent assigned, skipping notification`);
      return;
    }
    
    // Fetch technician data
    let fcmToken;
    let lanCode = "en";
    try {
      const technicianDoc = await admin
        .firestore()
        .collection("users")
        .doc(agent.uid)
        .get();

      if (technicianDoc.exists) {
        const technicianData = technicianDoc.data();
        fcmToken = technicianData?.fcmToken;
        lanCode = technicianData?.lanCode || "en";
      }
    } catch (error) {
      console.error(`[${bookingId}] Error fetching technician data:`, error);
    }

    // A missing token only means there is no push to send:
    // sendAndStoreNotification still writes the in-app record.
    if (!fcmToken || fcmToken.trim() === "") {
      console.log(`[${bookingId}] Technician has no valid FCM token; storing notification without a push`);
    }

    const customerName = afterData.customer?.name || "Customer";
    const serviceName = afterData.service?.name || "Service";
    const serviceNameAr = afterData.service?.name_ar || serviceName;
    const serviceNameUr = afterData.service?.name_ur || serviceNameAr || serviceName;

    await sendAndStoreNotification({
      targetRole: "technician",
      targetId: agent.uid,
      titleEn: "Payment Verification Required",
      titleAr: "مطلوب التحقق من الدفع",
      titleUr: "ادائیگی کی تصدیق درکار ہے",
      bodyEn: `${customerName} has completed the payment outside the app. Please verify the payment to complete the booking.`,
      bodyAr: `أكمل ${customerName} الدفع خارج التطبيق. يرجى التحقق من الدفع لإكمال الحجز.`,
      bodyUr: `${customerName} نے ایپ کے باہر ادائیگی مکمل کر لی ہے۔ براہ کرم بکنگ مکمل کرنے کے لیے ادائیگی کی تصدیق کریں۔`,
      data: {
        targetRole: "technician",
        category: "booking",
        bookingId: bookingId,
        serviceName: serviceName,
        serviceNameAr: serviceNameAr,
        serviceNameUr: serviceNameUr,
        requestId: `${bookingId}_VP`,
      },
      fcmToken: fcmToken,
      lanCode: lanCode,
    });
  }
);

// Booking Triggers
const bookingTriggers = require('./src/triggers/bookingTriggers');
exports.onBookingRequestCreated = bookingTriggers.onBookingRequestCreated;
exports.rebroadcastSearchingBookingRequests = bookingTriggers.rebroadcastSearchingBookingRequests;
exports.onManualJobOfferUpdated = bookingTriggers.onManualJobOfferUpdated;
exports.processAutoAssignments = bookingTriggers.processAutoAssignments;
exports.onAutoAssignmentRequestCreated = bookingTriggers.onAutoAssignmentRequestCreated;
exports.syncAgentToAutoAssignment = bookingTriggers.syncAgentToAutoAssignment;
exports.onBookingCreatedCleanupOffers = bookingTriggers.onBookingCreatedCleanupOffers;
exports.onBookingRequestDeletedCleanupOffers = bookingTriggers.onBookingRequestDeletedCleanupOffers;
exports.onJobOfferCreatedForRebook = bookingTriggers.onJobOfferCreatedForRebook;
exports.notifyOnTechnicianRegistrationStatusChange = bookingTriggers.notifyOnTechnicianRegistrationStatusChange;
// Both of these were defined but never exported, so neither was deployed:
// warranty claims that lost their technician notified nobody, and abandoned
// `booking_request` docs were only ever closed by the customer's 5-minute
// client-side timer — which dies with the app, leaving them 'searching' forever
// and inflating the admin dashboard's pending count.
exports.onBookingWarrantyUpdated = bookingTriggers.onBookingWarrantyUpdated;
exports.cleanupStaleBookingRequests = bookingTriggers.cleanupStaleBookingRequests;
exports.cleanupStaleJobRequests = bookingTriggers.cleanupStaleJobRequests;

