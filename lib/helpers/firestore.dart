import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AppFirestore {
  // customers collection
  static CollectionReference customersCollectionRef = FirebaseFirestore.instance
      .collection('customers');

  // users collection
  static CollectionReference usersCollectionRef = FirebaseFirestore.instance
      .collection('users');

  // locations collection
  static CollectionReference locationsCollectionRef = FirebaseFirestore.instance
      .collection('locations');

  // categories collection
  static CollectionReference categoriesCollectionRef = FirebaseFirestore
      .instance
      .collection('categories');

  // services collection
  static CollectionReference servicesCollectionRef = FirebaseFirestore.instance
      .collection('services');

  // bookings collection
  static CollectionReference bookingsCollectionRef = FirebaseFirestore.instance
      .collection('bookings');

  // highlighted services collection
  static CollectionReference highlightedServicesCollectionRef =
      FirebaseFirestore.instance.collection('highlighted_services');

  // banners collection
  static CollectionReference bannersCollectionRef = FirebaseFirestore.instance
      .collection('banners');
  // notification collection
  static CollectionReference notificationsCollectionRef = FirebaseFirestore
      .instance
      .collection('notifications');
  static CollectionReference tippingCollectionRef = FirebaseFirestore.instance
      .collection('tipping');
  static CollectionReference faqCollectionRef = FirebaseFirestore.instance
      .collection('faq');

  static CollectionReference customerServiceCollectionRef = FirebaseFirestore
      .instance
      .collection('customer_service_contacts');
  static CollectionReference transactionsCollectionRef = FirebaseFirestore
      .instance
      .collection('transactions');
  static CollectionReference payoutCollectionRef = FirebaseFirestore.instance
      .collection('payouts');

  // Unified wallet collection (replaces separate tip/earnings tracking)
  static CollectionReference unifiedWalletCollectionRef = FirebaseFirestore
      .instance
      .collection('unified_wallets');

  // Unified payout requests collection
  static CollectionReference unifiedPayoutRequestsCollectionRef =
      FirebaseFirestore.instance.collection('unified_payout_requests');

  // Payout history collection
  static CollectionReference payoutHistoryCollectionRef = FirebaseFirestore
      .instance
      .collection('payout_history');

  // Admnis collection
  static CollectionReference adminsCollectionRef = FirebaseFirestore.instance
      .collection('admins');

  // Pending admins collection
  static CollectionReference pendingAdminsCollectionRef = FirebaseFirestore
      .instance
      .collection('pending_admins');

  // job_offers collection
  static CollectionReference jobOffersCollectionRef = FirebaseFirestore.instance
      .collection('job_offers');

  // counter_offers collection
  static CollectionReference counterOffersCollectionRef = FirebaseFirestore
      .instance
      .collection('counter_offers');

  // job_requests collection
  static CollectionReference jobRequestsCollectionRef = FirebaseFirestore
      .instance
      .collection('job_requests');

  // booking_request collection
  static CollectionReference bookingRequestsCollectionRef = FirebaseFirestore
      .instance
      .collection('booking_request');

  // auto-assignment_requests collection
  static CollectionReference autoAssignmentRequestsCollectionRef =
      FirebaseFirestore.instance.collection('auto-assignment_requests');

  // app_settings collection (remote feature flags)
  static CollectionReference appSettingsCollectionRef = FirebaseFirestore
      .instance
      .collection('app_settings');
}

class AppFireStorage {
  // services images storage
  static Reference servicesStorageRef = FirebaseStorage.instance.ref(
    'services',
  );
  static Reference bannersStorageRef = FirebaseStorage.instance.ref('banners');

  // agent documents storage
  static Reference agentDocStorageRef = FirebaseStorage.instance.ref(
    'agent_doc',
  );

  // Category images storage
  static Reference categoryStorageRef = FirebaseStorage.instance.ref(
    'category',
  );

  // payout proofs storage
  static Reference payoutProofsStorageRef = FirebaseStorage.instance.ref(
    'payout_proofs',
  );
}
