import 'dart:async';
import 'dart:developer' as console;
import 'dart:math';
import 'package:aboglumbo_bbk_panel/models/payout_request.dart';
import 'package:aboglumbo_bbk_panel/models/transaction.dart';
import 'package:aboglumbo_bbk_panel/models/warranty.dart';
import 'package:aboglumbo_bbk_panel/models/notification_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:rxdart/rxdart.dart';
import 'package:aboglumbo_bbk_panel/helpers/custom_exception.dart';
import 'package:aboglumbo_bbk_panel/services/time_service.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/models/banner.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/models/categories.dart';
import 'package:aboglumbo_bbk_panel/models/customer.dart';
import 'package:aboglumbo_bbk_panel/models/counter_offer.dart';
import 'package:aboglumbo_bbk_panel/models/customer_support.dart';
import 'package:aboglumbo_bbk_panel/models/faq.dart';
import 'package:aboglumbo_bbk_panel/models/highlighted_services.dart';
import 'package:aboglumbo_bbk_panel/models/admin_dashboard_data.dart';
import 'package:aboglumbo_bbk_panel/models/location.dart';
import 'package:aboglumbo_bbk_panel/models/service.dart';
import 'package:aboglumbo_bbk_panel/models/tipping.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/models/admin.dart';
import 'package:aboglumbo_bbk_panel/models/unified_payout.dart';
import 'package:aboglumbo_bbk_panel/services/unified_payout_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class RawBookingRequest {
  final String id;
  final Map<String, dynamic> data;

  RawBookingRequest({required this.id, required this.data});
}

class AppServices {
  static Future<void> updateFCMToken(String token, {bool? isAdmin}) async {
    try {
      String userId = LocalStore.getUID() ?? '';
      if (userId.isEmpty) {
        debugPrint('❌ Cannot update FCM token: User ID is empty');
        return;
      }

      bool isUserAdmin = isAdmin ?? false;
      if (isAdmin == null) {
        UserModel? cachedUser = LocalStore.getCachedUserData();
        isUserAdmin =
            cachedUser?.isAdmin == true || cachedUser?.role == 'admin';
      }

      final collection = isUserAdmin
          ? AppFirestore.adminsCollectionRef
          : AppFirestore.usersCollectionRef;

      await collection.doc(userId).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': Timestamp.now(),
      });
      debugPrint(
        '✅ FCM token updated in ${isUserAdmin ? 'admins' : 'users'} collection',
      );
    } catch (e) {
      debugPrint('❌ Error updating FCM token: $e');
    }
  }

  static Future<void> clearFCMToken() async {
    try {
      String userId = LocalStore.getUID() ?? '';
      if (userId.isNotEmpty) {
        UserModel? cachedUser = LocalStore.getCachedUserData();
        bool isAdmin =
            cachedUser?.isAdmin == true || cachedUser?.role == 'admin';
        final collection = isAdmin
            ? AppFirestore.adminsCollectionRef
            : AppFirestore.usersCollectionRef;

        await collection.doc(userId).update({'fcmToken': FieldValue.delete()});
        if (kDebugMode) {
          print(
            '✅ FCM token cleared from ${isAdmin ? 'admins' : 'users'} collection',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing FCM token: $e');
      }
    }
  }

  static Future<void> storeNotificationInFirestore(
    RemoteMessage message,
  ) async {
    try {
      String userId = '';

      // Check if Hive is available (only in foreground)
      try {
        if (Hive.isBoxOpen('myBox')) {
          userId = LocalStore.getUID() ?? '';
        } else {
          // Background execution - try to get userId from message data
          userId = message.data['userId']?.toString() ?? '';

          debugPrint('⚠️ Background notification - Hive not available');
        }
      } catch (e) {
        debugPrint('⚠️ Error accessing LocalStore: $e');
        // Continue with empty userId if Hive is not available
        userId = message.data['userId']?.toString() ?? '';
      }

      // If we don't have a userId, we can't store the notification
      if (userId.isEmpty) {
        debugPrint('⚠️ No userId available, cannot store notification');
        return;
      }

      String title =
          message.notification?.title ??
          message.data['title'] ??
          'New Notification';
      String body =
          message.notification?.body ??
          message.data['body'] ??
          'You have a new notification';

      // Store notification data matching Cloud Functions format
      Map<String, dynamic> notificationData = {
        'titleEn': message.data['titleEn'] ?? title,
        'titleAr': message.data['titleAr'] ?? title,
        'bodyEn': message.data['bodyEn'] ?? body,
        'bodyAr': message.data['bodyAr'] ?? body,
        'data': message.data.isNotEmpty ? message.data : {},
        'read': false,
        'createdAt': Timestamp.now(),
      };

      // Store in user-specific subcollection: users/{userId}/notifications
      await AppFirestore.usersCollectionRef
          .doc(userId)
          .collection('notifications')
          .add(notificationData);

      debugPrint(
        '✅ Notification stored in users/$userId/notifications subcollection',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error storing notification in Firestore: $e');
      }
    }
  }

  static Future<bool> checkTheMailExists(String email) async {
    final snapshot = await AppFirestore.usersCollectionRef
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  static Future<void> updateUserProfile(
    UserModel user, {
    bool updateProfileUrl = false,
    bool updateDocUrl = false,
    bool updateCertifications = false,
    bool updateResidenceId = false,
    bool updateSponsorPermit = false,
    bool updateChamberApproval = false,
  }) async {
    try {
      String userId = user.uid ?? '';

      if (userId.isNotEmpty) {
        // Only include fields that are being updated
        Map<String, dynamic> userData = {
          'name': user.name,
          'phone': user.phone,
          'districtName': user.districtName,
          'jobRoles': user.jobRoles,
          'updatedAt': Timestamp.now(),
          'location': user.location?.toJson(),
          'last_known_location': user.lastKnownLocation,
          'geohash': user.geohash,
          'liveLocation': user.liveLocation?.toJson(),
        };

        // Only add image URLs if they were actually updated
        if (updateProfileUrl && user.profileUrl != null) {
          userData['profileUrl'] = user.profileUrl;
        }

        if (updateDocUrl && user.docUrl != null) {
          userData['docUrl'] = user.docUrl;
        }

        if (updateCertifications && user.certifications != null) {
          userData['certifications'] = user.certifications;
        }

        if (updateResidenceId && user.residenceIdUrl != null) {
          userData['residenceIdUrl'] = user.residenceIdUrl;
        }

        if (updateSponsorPermit && user.sponsorWorkPermitUrl != null) {
          userData['sponsorWorkPermitUrl'] = user.sponsorWorkPermitUrl;
        }

        if (updateChamberApproval &&
            user.chamberOfCommerceApprovalUrl != null) {
          userData['chamberOfCommerceApprovalUrl'] =
              user.chamberOfCommerceApprovalUrl;
        }

        bool isAdmin = user.isAdmin == true || user.role == 'admin';
        final collection = isAdmin
            ? AppFirestore.adminsCollectionRef
            : AppFirestore.usersCollectionRef;

        await collection.doc(userId).update(userData);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating user profile: $e');
      }
      rethrow;
    }
  }

  static Future<List<LocationModel>> getDistricts() async {
    try {
      final snapshot = await AppFirestore.locationsCollectionRef.get();
      return snapshot.docs
          .map(
            (doc) => LocationModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching districts: $e');
      }
      return [];
    }
  }

  static Future<void> updateWorkerLanguage(String language) async {
    try {
      String userId = LocalStore.getUID() ?? '';
      if (userId.isEmpty) {
        if (kDebugMode) {
          print('⚠️ No user logged in, cannot update worker language');
        }
        return;
      }

      UserModel? cachedUser = LocalStore.getCachedUserData();
      bool isAdmin = cachedUser?.isAdmin == true || cachedUser?.role == 'admin';
      final collection = isAdmin
          ? AppFirestore.adminsCollectionRef
          : AppFirestore.usersCollectionRef;

      await collection.doc(userId).update({'lanCode': language});

      // Update local storage cached user data
      if (cachedUser != null) {
        cachedUser.lanCode = language;
        await LocalStore.storeUserData(cachedUser);
      }

      // Update local storage cached admin data if admin
      if (isAdmin) {
        AdminModel? cachedAdmin = LocalStore.getCachedAdminData();
        if (cachedAdmin != null) {
          await LocalStore.storeAdminData(
            cachedAdmin.copyWith(lanCode: language),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating worker language: $e');
      }
    }
  }

  static Future<String> getCurrentUserRole() async {
    try {
      UserModel? cachedUser = LocalStore.getCachedUserData();
      if (cachedUser != null) {
        return cachedUser.isAdmin == true ? 'admin' : 'worker';
      }

      String userId = LocalStore.getUID() ?? '';
      if (userId.isNotEmpty) {
        DocumentSnapshot userDoc = await AppFirestore.usersCollectionRef
            .doc(userId)
            .get();
        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          bool isAdmin = userData['isAdmin'] ?? false;
          return isAdmin ? 'admin' : 'worker';
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting current user role: $e');
      }
    }
    return 'worker';
  }

  static Stream<List<NotificationModel>> getNotificationsStream() {
    String userId = LocalStore.getUID() ?? '';
    if (userId.isEmpty) {
      if (kDebugMode) print('getNotificationsStream: userId is empty');
      return Stream.value([]);
    }
    
    final bool isAdminMode = LocalStore.isCurrentUserAdmin();
    final collectionRef = isAdminMode 
        ? AppFirestore.adminsCollectionRef 
        : AppFirestore.usersCollectionRef;

    if (kDebugMode) {
      print('getNotificationsStream: isAdminMode=$isAdminMode, userId=$userId');
      print('getNotificationsStream: querying ${isAdminMode ? 'admins' : 'users'}/$userId/notifications');
    }

    return collectionRef
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          if (kDebugMode) {
            print('getNotificationsStream: got ${snapshot.docs.length} notifications');
          }
          return snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList();
        });
  }

  static Future<void> markFirestoreNotificationAsRead(
    String notificationId,
  ) async {
    String userId = LocalStore.getUID() ?? '';
    if (userId.isEmpty) return;

    final bool isAdminMode = LocalStore.isCurrentUserAdmin();
    final collectionRef = isAdminMode 
        ? AppFirestore.adminsCollectionRef 
        : AppFirestore.usersCollectionRef;

    await collectionRef
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  static Future<void> deleteFirestoreNotification(String notificationId) async {
    String userId = LocalStore.getUID() ?? '';
    if (userId.isEmpty) return;

    final bool isAdminMode = LocalStore.isCurrentUserAdmin();
    final collectionRef = isAdminMode 
        ? AppFirestore.adminsCollectionRef 
        : AppFirestore.usersCollectionRef;

    await collectionRef
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  static Future<void> markAllFirestoreNotificationsAsRead() async {
    String userId = LocalStore.getUID() ?? '';
    if (userId.isEmpty) return;

    final bool isAdminMode = LocalStore.isCurrentUserAdmin();
    final collectionRef = isAdminMode
        ? AppFirestore.adminsCollectionRef
        : AppFirestore.usersCollectionRef;

    final collection = collectionRef.doc(userId).collection('notifications');

    final snapshot = await collection.where('read', isEqualTo: false).get();
    if (snapshot.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  static Future<void> deleteAllFirestoreNotifications() async {
    String userId = LocalStore.getUID() ?? '';
    if (userId.isEmpty) return;

    final bool isAdminMode = LocalStore.isCurrentUserAdmin();
    final collectionRef = isAdminMode 
        ? AppFirestore.adminsCollectionRef 
        : AppFirestore.usersCollectionRef;

    final collection = collectionRef
        .doc(userId)
        .collection('notifications');

    final snapshot = await collection.get();
    final batch = FirebaseFirestore.instance.batch();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  static Stream<int> getUnreadNotificationsCountStream() {
    String userId = LocalStore.getUID() ?? '';
    if (userId.isEmpty) return Stream.value(0);

    final bool isAdminMode = LocalStore.isCurrentUserAdmin();
    final collectionRef = isAdminMode 
        ? AppFirestore.adminsCollectionRef 
        : AppFirestore.usersCollectionRef;

    return collectionRef
        .doc(userId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  static Future<bool> markAllNotificationsAsRead() async {
    String userId = LocalStore.getUID() ?? '';
    if (userId.isEmpty) return false;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final bool isAdminMode = LocalStore.isCurrentUserAdmin();
      final collectionRef = isAdminMode 
          ? AppFirestore.adminsCollectionRef 
          : AppFirestore.usersCollectionRef;

      final snapshot = await collectionRef
          .doc(userId)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserNotifications({
    int limit = 20,
    bool onlyUnread = false,
  }) async {
    try {
      String userId = LocalStore.getUID() ?? '';
      if (userId.isEmpty) {
        if (kDebugMode) {
          print('⚠️ No user logged in, cannot retrieve notifications');
        }
        return [];
      }

      UserModel? currentUser = LocalStore.getCachedUserData();
      bool isCurrentUserAdmin = currentUser?.isAdmin ?? false;
      String currentUserRole = isCurrentUserAdmin ? 'admin' : 'worker';

      final bool isAdminMode = LocalStore.isCurrentUserAdmin();
      final collectionRef = isAdminMode 
          ? AppFirestore.adminsCollectionRef 
          : AppFirestore.usersCollectionRef;

      // Query from subcollection: {collection}/{userId}/notifications
      Query query = collectionRef
          .doc(userId)
          .collection('notifications')
          .orderBy('createdAt', descending: true);

      if (onlyUnread) {
        query = query.where('read', isEqualTo: false);
      }

      QuerySnapshot querySnapshot = await query.limit(limit).get();

      List<Map<String, dynamic>> notifications = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // Convert to format expected by notifications page
        // Cloud Functions store: titleEn, titleAr, bodyEn, bodyAr
        // Notifications page expects: title, body (single language)
        return {
          'id': doc.id,
          'title': data['titleEn'] ?? data['titleAr'] ?? '',
          'body': data['bodyEn'] ?? data['bodyAr'] ?? '',
          'titleEn': data['titleEn'] ?? '',
          'titleAr': data['titleAr'] ?? '',
          'bodyEn': data['bodyEn'] ?? '',
          'bodyAr': data['bodyAr'] ?? '',
          'data': data['data'] ?? {},
          'isRead': data['read'] ?? false,
          'createdAt': data['createdAt'],
          'category':
              (data['data'] as Map<String, dynamic>?)?['category'] ?? 'general',
        };
      }).toList();

      if (kDebugMode) {
        print(
          '📱 Retrieved ${notifications.length} notifications for $currentUserRole from subcollection',
        );
      }

      return notifications;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error retrieving notifications: $e');
      }
      return [];
    }
  }

  static Stream<List<BookingModel>> getBookingsStream({
    String? bookingStatusCode,
    bool isAdmin = false,
  }) {
    if (isAdmin) {
      if (bookingStatusCode == 'X') {
        final customerCancel = AppFirestore.bookingsCollectionRef
            .where('bookingStatusCode', isEqualTo: 'XC')
            .snapshots()
            .map((snapshot) {
              return snapshot.docs
                  .map((doc) => BookingModel.fromDocumentSnapshot(doc))
                  .toList();
            });

        return customerCancel.map((customer) {
          final combined = [...customer];

          combined.sort((a, b) {
            final aTime = _getComparisonTimestamp(a);
            final bTime = _getComparisonTimestamp(b);
            return bTime.compareTo(aTime);
          });

          return combined;
        });
      } else if (bookingStatusCode == 'R') {
        return AppFirestore.bookingsCollectionRef
            .where('bookingStatusCode', isEqualTo: 'R')
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots()
            .map((snapshot) {
              return snapshot.docs
                  .map((doc) => BookingModel.fromDocumentSnapshot(doc))
                  .toList();
            });
      } else if (bookingStatusCode == 'CP') {
        return AppFirestore.bookingsCollectionRef
            .where('bookingStatusCode', whereIn: ['CP', 'VP'])
            .where('paymentCompleted', isEqualTo: false)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots()
            .map((snapshot) {
              return snapshot.docs
                  .map((doc) => BookingModel.fromDocumentSnapshot(doc))
                  .toList();
            });
      } else if (bookingStatusCode == 'C') {
        return AppFirestore.bookingsCollectionRef
            .where('bookingStatusCode', isEqualTo: bookingStatusCode)
            .where('paymentCompleted', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots()
            .map((snapshot) {
              return snapshot.docs
                  .map((doc) => BookingModel.fromDocumentSnapshot(doc))
                  .toList();
            });
      } else if (bookingStatusCode == 'P') {
        return AppFirestore.bookingsCollectionRef
            .where('bookingStatusCode', isEqualTo: 'P')
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots()
            .map((snapshot) {
              return snapshot.docs
                  .map((doc) => BookingModel.fromDocumentSnapshot(doc))
                  .toList();
            });
      } else {
        return AppFirestore.bookingsCollectionRef
            .where('bookingStatusCode', isEqualTo: bookingStatusCode)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots()
            .map((snapshot) {
              return snapshot.docs
                  .map((doc) => BookingModel.fromDocumentSnapshot(doc))
                  .toList();
            });
      }
    } else {
      String workerId = LocalStore.getUID() ?? '';

      if (bookingStatusCode == 'X' && !isAdmin) {
        final workerCancel = AppFirestore.bookingsCollectionRef
            .where('cancelledWorkerUids', arrayContains: workerId)
            .snapshots()
            .map((snapshot) {
              return snapshot.docs
                  .map((doc) => BookingModel.fromDocumentSnapshot(doc))
                  .toList();
            });

        final customerCancel = AppFirestore.bookingsCollectionRef
            .where('agent.uid', isEqualTo: workerId)
            .where('bookingStatusCode', isEqualTo: 'XC')
            .snapshots()
            .map((snapshot) {
              return snapshot.docs
                  .map((doc) => BookingModel.fromDocumentSnapshot(doc))
                  .toList();
            });

        return Rx.combineLatest2(customerCancel, workerCancel, (
          List<BookingModel> customer,
          List<BookingModel> worker,
        ) {
          final combined = [...customer, ...worker];

          combined.sort((a, b) {
            final aTime = _getComparisonTimestamp(a);
            final bTime = _getComparisonTimestamp(b);
            return bTime.compareTo(aTime);
          });

          return combined;
        });
      } else if (bookingStatusCode == 'CP') {
        return AppFirestore.bookingsCollectionRef
            .where('agent.uid', isEqualTo: workerId)
            .where('bookingStatusCode', whereIn: ['CP', 'VP'])
            .where('paymentCompleted', isEqualTo: false)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots()
            .map((snapshot) {
              return snapshot.docs
                  .map((doc) => BookingModel.fromDocumentSnapshot(doc))
                  .toList();
            });
      } else if (bookingStatusCode == 'C') {
        return AppFirestore.bookingsCollectionRef
            .where('agent.uid', isEqualTo: workerId)
            .where('bookingStatusCode', isEqualTo: bookingStatusCode)
            .where('paymentCompleted', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots()
            .map((snapshot) {
              return snapshot.docs
                  .map((doc) => BookingModel.fromDocumentSnapshot(doc))
                  .toList();
            });
      } else if (bookingStatusCode == 'P') {
        return AppFirestore.bookingsCollectionRef
            .where('agent.uid', isEqualTo: workerId)
            .where('bookingStatusCode', isEqualTo: 'P')
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots()
            .map((snapshot) {
              return snapshot.docs
                  .map((doc) => BookingModel.fromDocumentSnapshot(doc))
                  .toList();
            });
      } else {
        return AppFirestore.bookingsCollectionRef
            .where('agent.uid', isEqualTo: workerId)
            .where('bookingStatusCode', isEqualTo: bookingStatusCode)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots()
            .map((snapshot) {
              return snapshot.docs
                  .map((doc) => BookingModel.fromDocumentSnapshot(doc))
                  .toList();
            });
      }
    }
  }

  static int _getComparisonTimestamp(BookingModel booking) {
    if (booking.bookingStatusCode == 'XC') {
      return (booking.cancelledAt?.millisecondsSinceEpoch ?? 0);
    } else if (booking.bookingStatusCode == 'R') {
      return (booking.updatedAt?.millisecondsSinceEpoch ?? 0);
    } else {
      final workerCancelTime = _getWorkerCancelledAtTimestamp(booking);
      return workerCancelTime;
    }
  }

  static int _getWorkerCancelledAtTimestamp(BookingModel booking) {
    final currentWorkerId = LocalStore.getUID() ?? '';

    for (var worker in booking.cancelledWorkers) {
      if (worker.uid == currentWorkerId) {
        final timestamp = worker.cancelledAt;
        return timestamp.toDate().millisecondsSinceEpoch;
      }
    }
    return 0;
  }

  /// Get warranty repairs stream
  /// Fetches bookings where warranty != null, paymentCompleted = true, bookingStatusCode = 'C'
  /// Then filters by warranty status code
  static Stream<List<BookingModel>> getWarrantiesStream({
    String? warrantyStatusCode,
    bool isAdmin = false,
  }) {
    if (isAdmin) {
      // Admin sees all warranties
      return AppFirestore.bookingsCollectionRef
          .where('bookingStatusCode', isEqualTo: 'C')
          .where('paymentCompleted', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => BookingModel.fromDocumentSnapshot(doc))
                .where((booking) {
                  // Filter only bookings with warranty
                  if (booking.warranty == null) return false;

                  // Filter by warranty status if specified
                  if (warrantyStatusCode != null) {
                    return booking.warranty!.warrantyStatusCode ==
                        warrantyStatusCode;
                  }
                  return true;
                })
                .toList();
          });
    } else {
      // Technician sees warranties they're assigned to OR have rejected
      String workerId = LocalStore.getUID() ?? '';

      return AppFirestore.bookingsCollectionRef
          .where('bookingStatusCode', isEqualTo: 'C')
          .where('paymentCompleted', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => BookingModel.fromDocumentSnapshot(doc))
                .where((booking) {
                  // Filter only bookings with warranty
                  if (booking.warranty == null) return false;

                  // Check if technician is assigned to this warranty
                  bool isAssigned =
                      booking.warranty!.assignedTechnician?.uid == workerId ||
                      booking.warranty!.assignedTechnicianId == workerId;

                  // Check if technician has rejected this warranty
                  bool hasRejected =
                      booking.warranty!.rejectedTechnicians?.any(
                        (tech) => tech.uid == workerId,
                      ) ??
                      false;

                  // Include if assigned OR rejected
                  if (!isAssigned && !hasRejected) return false;

                  // Filter by warranty status if specified
                  if (warrantyStatusCode != null) {
                    // Special handling for 'X' (Rejected) tab for technicians
                    if (warrantyStatusCode == 'X') {
                      // Show only warranties this technician has rejected
                      return hasRejected;
                    } else {
                      // For other tabs, show only if NOT rejected by this technician
                      // and the warranty status matches
                      return !hasRejected &&
                          booking.warranty!.warrantyStatusCode ==
                              warrantyStatusCode;
                    }
                  }
                  return true;
                })
                .toList();
          });
    }
  }

  static Stream<List<BookingModel>> getBookingsStreamByStatus(
    String bookingStatusCode,
  ) {
    if (bookingStatusCode == 'X') {
      final customerCancelled = AppFirestore.bookingsCollectionRef
          .where('bookingStatusCode', isEqualTo: 'XC')
          .snapshots()
          .map((snapshot) {
            final list = snapshot.docs
                .map((doc) => BookingModel.fromDocumentSnapshot(doc))
                .toList();
            return list;
          })
          .startWith([]);

      final adminCancelled = AppFirestore.bookingsCollectionRef
          .where('bookingStatusCode', isEqualTo: 'R')
          .snapshots()
          .map((snapshot) {
            final list = snapshot.docs
                .map((doc) => BookingModel.fromDocumentSnapshot(doc))
                .toList();
            return list;
          })
          .startWith([]);

      return Rx.combineLatest2(customerCancelled, adminCancelled, (
        List<BookingModel> customer,
        List<BookingModel> admin,
      ) {
        final combined = [...customer, ...admin];

        combined.sort((a, b) {
          final aTime = _getComparisonTimestamp(a);
          final bTime = _getComparisonTimestamp(b);
          return bTime.compareTo(aTime); // Swap to descending
        });

        return combined;
      });
    }
    if (bookingStatusCode == 'CP') {
      return AppFirestore.bookingsCollectionRef
          .where('bookingStatusCode', whereIn: ['CP', 'VP'])
          .where('paymentCompleted', isEqualTo: false)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => BookingModel.fromDocumentSnapshot(doc))
                .toList(),
          );
    } else {
      Query query = AppFirestore.bookingsCollectionRef
          .where('bookingStatusCode', isEqualTo: bookingStatusCode)
          .orderBy('createdAt', descending: true);

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => BookingModel.fromDocumentSnapshot(doc))
            .toList();
      });
    }
  }

  static Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      final doc = await AppFirestore.bookingsCollectionRef.doc(bookingId).get();
      if (doc.exists) {
        return BookingModel.fromDocumentSnapshot(doc);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching booking by ID: $e');
      }
      return null;
    }
  }

  static Stream<List<CategoryModel>> getAllCategoriesStream() {
    return AppFirestore.categoriesCollectionRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => CategoryModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    });
  }

  static Future<List<CategoryModel>> getCategoriesByIds(
    List<String> categoryIds,
  ) async {
    if (categoryIds.isEmpty) return [];

    // Split into chunks of 10 due to Firestore whereIn limit
    List<List<String>> chunks = [];
    for (int i = 0; i < categoryIds.length; i += 10) {
      chunks.add(categoryIds.sublist(i, min(i + 10, categoryIds.length)));
    }

    // Fetch all chunks in parallel
    List<Future<QuerySnapshot>> futures = chunks
        .map(
          (chunk) => FirebaseFirestore.instance
              .collection('categories')
              .where(FieldPath.documentId, whereIn: chunk)
              .get(),
        )
        .toList();

    List<QuerySnapshot> snapshots = await Future.wait(futures);

    List<CategoryModel> categories = [];
    for (var snapshot in snapshots) {
      categories.addAll(
        snapshot.docs
            .map(
              (doc) => CategoryModel.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }),
            )
            .toList(),
      );
    }

    return categories;
  }

  static Stream<List<ServiceModel>> getAllServicesStream() {
    return AppFirestore.servicesCollectionRef.snapshots().map((snapshot) {
      final services = snapshot.docs
          .map((doc) => ServiceModel.fromQueryDocumentSnapshot(doc))
          .toList();
      // Sort by category first, then by name
      services.sort((a, b) {
        int catComp = (a.category ?? '').compareTo(b.category ?? '');
        if (catComp != 0) return catComp;
        return (a.name ?? '').compareTo(b.name ?? '');
      });
      return services;
    });
  }

  static Stream<List<HighlightedServicesModel>>
  getAllHighlightedServicesStream() {
    return AppFirestore.highlightedServicesCollectionRef.snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => HighlightedServicesModel.fromQueryDocumentSnapshot(doc))
          .toList();
    });
  }

  static Stream<List<BannerModel>> getAllBannersStream() {
    return AppFirestore.bannersCollectionRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BannerModel.fromDocumentSnapshot(doc))
          .toList();
    });
  }

  static Stream<List<UserModel>> getAllAgentsStream() {
    return AppFirestore.usersCollectionRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return UserModel.fromDocumentSnapshot(doc);
                } catch (e) {
                  if (kDebugMode) {
                    print('⚠️ Error parsing user document ${doc.id}: $e');
                  }
                  return null;
                }
              })
              .whereType<UserModel>() // Filter out nulls
              .toList();
        });
  }

  static Stream<List<AdminModel>> getAdminsStream() {
    return AppFirestore.adminsCollectionRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => AdminModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                  id: doc.id,
                ),
              )
              .toList();
        });
  }

  static Stream<List<AdminModel>> getPendingAdminsStream() {
    return AppFirestore.pendingAdminsCollectionRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => AdminModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                  id: doc.id,
                ),
              )
              .toList();
        });
  }

  static Stream<List<TippingModel>> getTippingStream() {
    return AppFirestore.tippingCollectionRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => TippingModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    });
  }

  static Future<bool> clearTippingAmount(
    String agentId,
    String transactionId,
    XFile? image,
    TippingModel? tipmodel,
  ) async {
    try {
      String? imageUrl;
      if (image != null) {
        imageUrl = await _uploadProofImage(agentId, image);
        if (imageUrl == null) {
          if (kDebugMode) {
            print('❌ Failed to upload proof image');
          }
          return false;
        }
      }
      final model = AllTipsModel(
        agentId: agentId,
        createdAt: Timestamp.fromDate(DateTime.now()),
        totalTipAmount: tipmodel?.cardtip,
        paymentMethod: "card",
        id: agentId,
        updatedAt: Timestamp.now(),
        proofs: [
          {'transactionId': transactionId, 'proofImageUrl': imageUrl},
        ],
      );
      await AppFirestore.tippingCollectionRef
          .doc(agentId)
          .collection('tipPayoutCollectionsRef')
          .doc(agentId)
          .set({
            'tipdata': FieldValue.arrayUnion([model.toJson()]),
          }, SetOptions(merge: true));

      await AppFirestore.tippingCollectionRef.doc(agentId).update({
        'cardtip': 0.0,
        'payoutRequested': false,
        'updatedAt': Timestamp.now(),
        'payoutAmount': FieldValue.increment(tipmodel?.cardtip ?? 0.0),
      });

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing tipping amount: $e');
      }
      return false;
    }
  }

  static Future<String?> _uploadProofImage(String agentId, XFile image) async {
    try {
      // Read image as bytes
      final Uint8List imageData = await image.readAsBytes();

      // Create a unique filename with timestamp
      final String fileName =
          'payment_proof_${agentId}_${DateTime.now().millisecondsSinceEpoch}.${image.name.split('.').last}';

      // Create Firebase Storage reference
      final Reference storageRef = AppFireStorage.payoutProofsStorageRef
          .child('tip_payment_proofs')
          .child(agentId)
          .child(fileName);

      // Set metadata for the file
      final SettableMetadata metadata = SettableMetadata(
        contentType: _getContentType(image.name),
        customMetadata: {
          'uploadedBy': 'admin',
          'agentId': agentId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Upload the file
      final UploadTask uploadTask = storageRef.putData(imageData, metadata);

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get the download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      if (kDebugMode) {
        print('✅ Image uploaded successfully: $downloadUrl');
      }

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error uploading image: $e');
      }
      return null;
    }
  }

  // Helper method to determine content type based on file extension
  static String _getContentType(String fileName) {
    final String extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  static Future<bool> approveOrRejectAgent(
    String agentId,
    bool isApproved, {
    String? rejectionReason,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'isVerified': isApproved,
        'isDocsPendingReview': false, // Decision made, pending state cleared
        'updatedAt': Timestamp.now(),
      };

      if (!isApproved && rejectionReason != null) {
        updateData['rejectionReason'] = rejectionReason;
      } else if (isApproved) {
        updateData['rejectionReason'] = FieldValue.delete();
      }

      await AppFirestore.usersCollectionRef.doc(agentId).update(updateData);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error approving/rejecting agent: $e');
      }
      return false;
    }
  }

  static Future<bool> blockOrUnblockAgent(
    String agentId,
    bool isBlocked,
  ) async {
    try {
      await AppFirestore.usersCollectionRef.doc(agentId).update({
        'isBlocked': isBlocked,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error blocking/unblocking agent: $e');
      }
      return false;
    }
  }

  static Future<bool> addBanner(BannerModel banner, String bannerId) async {
    try {
      await AppFirestore.bannersCollectionRef
          .doc(bannerId)
          .set(banner.toJson());
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding banner: $e');
      }
      return false;
    }
  }

  static Future<bool> updateBanner(BannerModel banner) async {
    try {
      await AppFirestore.bannersCollectionRef
          .doc(banner.id)
          .update(banner.toJson());
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating banner: $e');
      }
      return false;
    }
  }

  static Future<bool> deleteBanner(String bannerId) async {
    try {
      await AppFirestore.bannersCollectionRef.doc(bannerId).delete();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting banner: $e');
      }
      return false;
    }
  }

  static Stream<List<UserModel>> getCatagoryWiseWorkersStream(
    String categoryId,
  ) {
    Query query = AppFirestore.usersCollectionRef
        .where('isVerified', isEqualTo: true)
        .where('isAdmin', isNotEqualTo: true)
        .where('jobRoles', arrayContains: categoryId);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromDocumentSnapshot(doc))
          .toList();
    });
  }

  /// Whether a `booking_request` doc is still live from the client's point of
  /// view, independent of the server-side cleanup cron.
  ///
  /// Mirrors the customer app's own `showExpiredScreen` rule
  /// (embedded_technician_search.dart): nobody has 120 seconds to accept
  /// before the search is considered a failed attempt — the customer has to
  /// explicitly "Search again" (a fresh request doc), not sit on a dead card
  /// for the rest of the 5-minute window. Once someone HAS accepted, the
  /// customer is actively choosing between candidates for up to 5 minutes
  /// total, so the card stays live for that whole window.
  ///
  /// Single source of truth on purpose: the Pending tab hides these cards on
  /// this rule, so any other surface counting the same requests (the admin
  /// dashboard tile) has to expire them on exactly the same rule or it reports
  /// a backlog that the tab refuses to show.
  static bool isBookingRequestLive(Map<String, dynamic> data, {DateTime? now}) {
    final status = data['status']?.toString();
    if (status != 'pending' && status != 'searching') return false;

    final createdAt = data['createdAt'] as Timestamp?;
    if (createdAt == null) return true;

    final elapsed = (now ?? TimeService.now).difference(createdAt.toDate());
    final acceptedTechnicians = data['acceptedTechnicians'] as List? ?? [];
    if (acceptedTechnicians.isEmpty) {
      return elapsed < const Duration(seconds: 120);
    }
    return elapsed < const Duration(minutes: 5);
  }

  /// Ticks once a second so time-based filters re-evaluate without waiting for
  /// a new Firestore snapshot.
  static Stream<int> _expiryTicker() =>
      Stream.periodic(const Duration(seconds: 1), (i) => i).startWith(0);

  static Stream<List<RawBookingRequest>> getBookingRequestsStream() {
    final firestoreStream = AppFirestore.bookingRequestsCollectionRef
        .where('status', whereIn: ['pending', 'searching'])
        .snapshots();

    // Combine with a periodic timer so an expired request disappears
    // immediately client-side, instead of waiting for the server cleanup
    // cron (which can lag up to 2 minutes).
    return Rx.combineLatest2(
      firestoreStream,
      _expiryTicker(),
      (snapshot, _) => snapshot,
    ).map((snapshot) {
      final now = TimeService.now;
      return snapshot.docs
          .map(
            (doc) => RawBookingRequest(
              id: doc.id,
              data: doc.data() as Map<String, dynamic>,
            ),
          )
          .where((request) => isBookingRequestLive(request.data, now: now))
          .toList();
    }).onErrorReturn([]);
  }

  static Future<bool> isEmailRegistered(String email) async {
    try {
      final snapshot = await AppFirestore.usersCollectionRef
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking email registration: $e');
      }
      return false;
    }
  }

  static Future<bool> checkThePhoneExists(String phone) async {
    final snapshot = await AppFirestore.usersCollectionRef
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  static Future<bool> cancelBooking(
    String bookingId, {
    required String agentUid,
    required String agentName,
  }) async {
    try {
      final cancelledAt = DateTime.now();

      await AppFirestore.bookingsCollectionRef.doc(bookingId).update({
        'cancelledWorkers': FieldValue.arrayUnion([
          {'uid': agentUid, 'agentName': agentName, 'cancelledAt': cancelledAt},
        ]),
        'cancelledWorkerUids': FieldValue.arrayUnion([agentUid]),
        'agent': FieldValue.delete(),
        'bookingStatusCode': 'P',
        'acceptedAt': FieldValue.delete(),
        'cancelledBy': 'worker',
        'updatedAt': cancelledAt,
      });

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error canceling booking: $e');
      }
      return false;
    }
  }

  /// Reads the service's *general* price straight from `services/{id}`.
  ///
  /// It cannot be taken from `booking.service.price`: all three booking
  /// creation paths overwrite that field with the resolved on-hour/off-hour
  /// band price at booking time (`service.copyWith(price: bookingTimePrice)` in
  /// the customer app's `save_booking.dart`), so on the booking document
  /// `service.price` is the frozen charged amount, not the general price.
  ///
  /// Returns 0 when the service has been deleted or carries no general price;
  /// the bonus then simply has no fallback basis for this job, which is the
  /// same outcome as before this field existed.
  static Future<double> _fetchGeneralServicePrice(String? serviceId) async {
    if (serviceId == null || serviceId.isEmpty) return 0.0;
    try {
      final doc = await AppFirestore.servicesCollectionRef.doc(serviceId).get();
      if (!doc.exists) return 0.0;
      final data = doc.data() as Map<String, dynamic>?;
      return (data?['price'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not read general price for service $serviceId: $e');
      }
      return 0.0;
    }
  }

  static Future<bool> completeBooking({
    required String bookingId,
    required String technicianId,
    required int mode,
    required List<String> fileUrls,
    required double serviceCost,
    required List<Map<String, dynamic>> serviceItems,
    required double totalCost,
    required double inspectionFee,
    String? serviceId,
  }) async {
    try {
      // Determine booking status based on inspection fee and service type
      // If inspection fee is 0 and mode is 0 (inspection only, no full service),
      // mark booking as completed directly instead of pending payment
      final bool isInspectionOnlyWithZeroFee = inspectionFee == 0 && mode == 0;
      final String status = isInspectionOnlyWithZeroFee ? 'C' : 'CP';

      // Captured at completion for the monthly bonus only, and never shown to
      // the customer (`CompletionDataModel` in the customer app parses named
      // fields, so an extra key is invisible there). `applyMonthlyBonus` uses
      // it as the bonus basis when `inspectionFee` is 0 because the booking's
      // on-hour/off-hour band carries no price. Recorded here rather than
      // looked up by the monthly cron so the value is the one that applied
      // when the job was done, and so the cron stays a fixed number of reads.
      final double generalServicePrice = await _fetchGeneralServicePrice(
        serviceId,
      );

      await AppFirestore.bookingsCollectionRef.doc(bookingId).update({
        'bookingStatusCode': status,
        'isStarted': false,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'paymentCompleted': isInspectionOnlyWithZeroFee ? true : false,
        'paymentRequestedAt': FieldValue.serverTimestamp(),
        'completionData': {
          'fileUrls': fileUrls,
          'serviceCost': serviceCost,
          'serviceItems': serviceItems,
          'totalCost': totalCost,
          'mode': mode,
          'inspectionFee': inspectionFee,
          'generalServicePrice': generalServicePrice,
        },
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error completing booking: $e');
      }
      return false;
    }
  }

  static Future<void> addFaq(FaqModel faqEntry) async {
    try {
      final querySnapshot = await AppFirestore.faqCollectionRef
          .where('stand', isEqualTo: faqEntry.stand)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        throw DuplicateStandException(
          'FAQ with the same stand already exists.',
        );
      }

      final newFaqId = AppFirestore.faqCollectionRef.doc().id;
      final faqToSave = FaqModel(
        faqEntry.stand,
        id: newFaqId,
        questionEn: faqEntry.questionEn,
        questionAr: faqEntry.questionAr,
        answerEn: faqEntry.answerEn,
        answerAr: faqEntry.answerAr,
      );

      await AppFirestore.faqCollectionRef.doc(newFaqId).set(faqToSave.toMap());
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> updateFaq(FaqModel faqEntry) async {
    try {
      await AppFirestore.faqCollectionRef
          .doc(faqEntry.id)
          .update(faqEntry.toMap());
    } catch (e) {
      rethrow;
    }
  }

  static Stream<List<FaqModel>> getFaqStream() {
    return AppFirestore.faqCollectionRef
        .orderBy('stand', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => FaqModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();
        });
  }

  static Future<bool> deleteFaq(String faqId) async {
    try {
      await AppFirestore.faqCollectionRef.doc(faqId).delete();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting FAQ: $e');
      }
      return false;
    }
  }

  static Stream<List<CustomerModel>> getAllCustomersStream() {
    return AppFirestore.customersCollectionRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return CustomerModel.fromJson(
                    doc.data() as Map<String, dynamic>,
                  );
                } catch (e) {
                  if (kDebugMode) {
                    print('⚠️ Error parsing customer document ${doc.id}: $e');
                  }
                  return null;
                }
              })
              .whereType<CustomerModel>() // Filter out nulls
              .toList();
        });
  }

  static Future<bool> blockUnblockCustomer(
    String customerId,
    bool isBlocked,
  ) async {
    try {
      await AppFirestore.customersCollectionRef.doc(customerId).update({
        'isBlocked': isBlocked,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error approving/rejecting agent: $e');
      }
      return false;
    }
  }

  static Future addCustomerServiceDetails(CustomerSupportModel contact) async {
    final uid = AppFirestore.customerServiceCollectionRef.doc().id;

    // Create a new contact model with the generated ID
    final contactWithId = contact.copyWith(id: uid);

    // Save the document with the ID included in the data
    await AppFirestore.customerServiceCollectionRef
        .doc(uid)
        .set(contactWithId.toJson());
  }

  static Stream<List<CustomerSupportModel>> getCustomerServiceStreamByType(
    String type,
  ) {
    return AppFirestore.customerServiceCollectionRef
        .where('type', isEqualTo: type)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => CustomerSupportModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
        });
  }

  static Future<bool> deleteCustomerService(String id) async {
    try {
      await AppFirestore.customerServiceCollectionRef.doc(id).delete();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting customer service: $e');
      }
      return false;
    }
  }

  static Future<bool> updateCustomerService(
    CustomerSupportModel contact,
  ) async {
    try {
      await AppFirestore.customerServiceCollectionRef
          .doc(contact.id)
          .update(contact.toJson());
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating customer service: $e');
      }
      return false;
    }
  }

  // In app_services.dart
  static Future<List<CustomerSupportModel>> getCustomerServiceByType(
    String type,
  ) async {
    try {
      final querySnapshot = await AppFirestore.customerServiceCollectionRef
          .where('type', isEqualTo: type)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => CustomerSupportModel.fromJson(
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Method to get a single contact by ID
  static Future<CustomerSupportModel?> getCustomerServiceById(String id) async {
    try {
      final docSnapshot = await AppFirestore.customerServiceCollectionRef
          .doc(id)
          .get();

      if (docSnapshot.exists) {
        return CustomerSupportModel.fromJson(
          docSnapshot.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  static Stream<List<CustomerSupportModel>> getCustomerSupportdata() {
    return AppFirestore.customerServiceCollectionRef
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          List<CustomerSupportModel> customerSupportList = snapshot.docs
              .map(
                (doc) => CustomerSupportModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
          return customerSupportList;
        });
  }

  static Future<TippingModel> getWorkerTippingData(String workerId) async {
    final snapshot = await AppFirestore.tippingCollectionRef
        .where('agentId', isEqualTo: workerId)
        .get();

    if (snapshot.docs.isEmpty) {
      return TippingModel(agentId: workerId);
    }

    return TippingModel.fromJson(
      snapshot.docs.first.data() as Map<String, dynamic>,
    );
  }

  static Future<List<ReviewModel>> getWorkerReviewsWithTipAmounts(
    String workerId,
  ) async {
    final snapshot = await AppFirestore.bookingsCollectionRef
        .where('review.workerId', isEqualTo: workerId)
        .get();
    return snapshot.docs
        .map((doc) => ReviewModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  static Future<double> getTotalTipping(String workerId) async {
    final snapshot = await AppFirestore.tippingCollectionRef
        .doc(workerId)
        .collection('total')
        .where('id', isEqualTo: workerId)
        .get();

    // Check if snapshot has documents before accessing .first
    if (snapshot.docs.isEmpty) {
      return 0.0;
    }

    final amount = snapshot.docs.first['amount'] as num? ?? 0.0;
    return amount.toDouble();
  }

  static Future<List<TransactionModel>> getWorkerTransactions(
    String workerId,
  ) async {
    final snapshot = await AppFirestore.transactionsCollectionRef
        .where('workerId', isEqualTo: workerId)
        .get();
    return snapshot.docs
        .map(
          (doc) =>
              TransactionModel.fromJson(doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  static Stream<List<PayoutAccountModel>> getPayoutAccount(String userId) {
    return AppFirestore.usersCollectionRef.doc(userId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return <PayoutAccountModel>[];

      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null || data['payoutAccounts'] == null) {
        return <PayoutAccountModel>[];
      }

      return List<PayoutAccountModel>.from(
        data['payoutAccounts'].map((x) => PayoutAccountModel.fromJson(x)),
      );
    });
  }

  // Add a new payout account
  static Future<void> addPayoutAccount({
    required String userId,
    required String accountHolderName,
    required String accountNumber,
    required String bankName,
    required String ifscCode,
    required bool isPrimary,
  }) async {
    // Get current user document
    final userDoc = await AppFirestore.usersCollectionRef.doc(userId).get();
    final userData = userDoc.data() as Map<String, dynamic>?;

    List<PayoutAccountModel> currentAccounts = [];
    if (userData != null && userData['payoutAccounts'] != null) {
      currentAccounts = List<PayoutAccountModel>.from(
        userData['payoutAccounts'].map((x) => PayoutAccountModel.fromJson(x)),
      );
    }

    // If setting as primary, remove primary status from all other accounts
    if (isPrimary) {
      currentAccounts = currentAccounts.map((account) {
        return account.copyWith(isPrimary: false);
      }).toList();
    }

    // Create new account with unique ID
    final newAccount = PayoutAccountModel(
      id: const Uuid().v4(),
      accountHolderName: accountHolderName,
      accountNumber: accountNumber,
      bankName: bankName,
      ifscCode: ifscCode.toUpperCase(),
      isPrimary: isPrimary,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );

    // Add new account to the list
    currentAccounts.add(newAccount);

    // Update the user document
    await AppFirestore.usersCollectionRef.doc(userId).update({
      'payoutAccounts': currentAccounts.map((a) => a.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update an existing payout account
  static Future<void> updatePayoutAccount({
    required String userId,
    required String accountId,
    required String accountHolderName,
    required String accountNumber,
    required String bankName,
    required String ifscCode,
    required bool isPrimary,
  }) async {
    // Get current user document
    final userDoc = await AppFirestore.usersCollectionRef.doc(userId).get();
    final userData = userDoc.data() as Map<String, dynamic>?;

    if (userData == null || userData['payoutAccounts'] == null) {
      throw Exception('No payout accounts found');
    }

    List<PayoutAccountModel> currentAccounts = List<PayoutAccountModel>.from(
      userData['payoutAccounts'].map((x) => PayoutAccountModel.fromJson(x)),
    );

    // Find the account to update
    final accountIndex = currentAccounts.indexWhere((a) => a.id == accountId);
    if (accountIndex == -1) {
      throw Exception('Account not found');
    }

    // If setting as primary, remove primary status from all other accounts
    if (isPrimary) {
      currentAccounts = currentAccounts.map((account) {
        return account.copyWith(isPrimary: false);
      }).toList();
    }

    // Update the account
    currentAccounts[accountIndex] = currentAccounts[accountIndex].copyWith(
      accountHolderName: accountHolderName,
      accountNumber: accountNumber,
      bankName: bankName,
      ifscCode: ifscCode.toUpperCase(),
      isPrimary: isPrimary,
      updatedAt: Timestamp.now(),
    );

    // Update the user document
    await AppFirestore.usersCollectionRef.doc(userId).update({
      'payoutAccounts': currentAccounts.map((a) => a.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Set a payout account as primary
  static Future<void> setPrimaryPayoutAccount({
    required String userId,
    required String accountId,
  }) async {
    // Get current user document
    final userDoc = await AppFirestore.usersCollectionRef.doc(userId).get();
    final userData = userDoc.data() as Map<String, dynamic>?;

    if (userData == null || userData['payoutAccounts'] == null) {
      throw Exception('No payout accounts found');
    }

    List<PayoutAccountModel> currentAccounts = List<PayoutAccountModel>.from(
      userData['payoutAccounts'].map((x) => PayoutAccountModel.fromJson(x)),
    );

    // Update all accounts - set all to non-primary, then set the target as primary
    currentAccounts = currentAccounts.map((account) {
      if (account.id == accountId) {
        return account.copyWith(isPrimary: true, updatedAt: Timestamp.now());
      } else {
        return account.copyWith(isPrimary: false);
      }
    }).toList();

    // Update the user document
    await AppFirestore.usersCollectionRef.doc(userId).update({
      'payoutAccounts': currentAccounts.map((a) => a.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete a payout account
  static Future<void> deletePayoutAccount({
    required String userId,
    required String accountId,
  }) async {
    // Get current user document
    final userDoc = await AppFirestore.usersCollectionRef.doc(userId).get();
    final userData = userDoc.data() as Map<String, dynamic>?;

    if (userData == null || userData['payoutAccounts'] == null) {
      throw Exception('No payout accounts found');
    }

    List<PayoutAccountModel> currentAccounts = List<PayoutAccountModel>.from(
      userData['payoutAccounts'].map((x) => PayoutAccountModel.fromJson(x)),
    );

    // Remove the account
    currentAccounts.removeWhere((account) => account.id == accountId);

    // Update the user document
    await AppFirestore.usersCollectionRef.doc(userId).update({
      'payoutAccounts': currentAccounts.map((a) => a.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get primary payout account
  static Future<PayoutAccountModel?> getPrimaryPayoutAccount(
    String userId,
  ) async {
    final userDoc = await AppFirestore.usersCollectionRef.doc(userId).get();
    final userData = userDoc.data() as Map<String, dynamic>?;

    if (userData == null || userData['payoutAccounts'] == null) {
      return null;
    }

    List<PayoutAccountModel> accounts = List<PayoutAccountModel>.from(
      userData['payoutAccounts'].map((x) => PayoutAccountModel.fromJson(x)),
    );

    try {
      return accounts.firstWhere((account) => account.isPrimary);
    } catch (e) {
      return null;
    }
  }

  // Get all payout accounts (not as stream)
  static Future<List<PayoutAccountModel>> getPayoutAccountsList(
    String userId,
  ) async {
    final userDoc = await AppFirestore.usersCollectionRef.doc(userId).get();
    final userData = userDoc.data() as Map<String, dynamic>?;

    if (userData == null || userData['payoutAccounts'] == null) {
      return <PayoutAccountModel>[];
    }

    return List<PayoutAccountModel>.from(
      userData['payoutAccounts'].map((x) => PayoutAccountModel.fromJson(x)),
    );
  }

  static Future<void> requestPayout(
    String amount,
    String? userId,
    String type,
  ) async {
    final newId = AppFirestore.payoutCollectionRef.doc().id;

    userId ??= LocalStore.getUID() ?? '';

    final primaryBankAcount = await getPrimaryPayoutAccount(userId);

    await AppFirestore.payoutCollectionRef.doc(newId).set({
      'id': newId,
      'amount': amount,
      'userId': userId,
      'status': 'P',
      'type': type,
      'payoutAccount': primaryBankAcount
          ?.toJson(), // Convert to JSON before saving
      'createdAt': Timestamp.now(),
    });
  }

  static Stream<List<PayoutRequestModel>> getPayoutRequestsById(String userId) {
    return AppFirestore.payoutCollectionRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => PayoutRequestModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
        });
  }

  static Future<void> deletePayoutRequest(String payoutRequestId) async {
    await AppFirestore.payoutCollectionRef.doc(payoutRequestId).delete();
  }

  static Stream<List<PayoutRequestModel>> getAllPayoutRequests() {
    return AppFirestore.payoutCollectionRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) =>
                PayoutRequestModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    });
  }

  static Stream<Map<String, dynamic>> getAllPayoutsAndTechnicians() {
    final payoutRequests = AppServices.getAllPayoutRequests();
    final technicians = AppServices.getAllAgentsStream();

    return Rx.combineLatest2(payoutRequests, technicians, (
      payouts,
      technicians,
    ) {
      return {'payouts': payouts, 'technicians': technicians};
    });
  }

  static Future<double> getWorkerAvailableBalance(String workerId) async {
    final balance = await AppFirestore.usersCollectionRef
        .doc(workerId)
        .get()
        .then(
          (snapshot) =>
              (snapshot.data() as Map<String, dynamic>?)?['availableBalance']
                  as num? ??
              0.0,
        );
    return balance.toDouble();
  }

  static Future<double> getWorkerPaidAmounts(String workerId) async {
    final paidAmounts = await AppFirestore.usersCollectionRef
        .doc(workerId)
        .get()
        .then(
          (snapshot) =>
              (snapshot.data() as Map<String, dynamic>?)?['paidAmounts']
                  as num? ??
              0.0,
        );
    return paidAmounts.toDouble();
  }

  static Future<double> getWorkerBonusAmounts(String workerId) async {
    final snapshot = await AppFirestore.usersCollectionRef.doc(workerId).get();
    final data = snapshot.data() as Map<String, dynamic>?;
    return (data?['totalMonthlyBonus'] as num?)?.toDouble() ?? 0.0;
  }

  static Future<UserModel> getWorkerById(String workerId) async {
    final snapshot = await AppFirestore.usersCollectionRef.doc(workerId).get();
    return UserModel.fromJson(snapshot.data() as Map<String, dynamic>);
  }

  static Stream<List<TippingModel>> getTipsPayoutStream() {
    return AppFirestore.tippingCollectionRef.snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => TippingModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  static Future<List<AllTipsModel>> getTipsById(String workerId) async {
    try {
      // Get the specific document
      final docPath = 'tipping/$workerId/totalTipsCollectionRef/$workerId';
      debugPrint('🔍 Querying tips from path: $docPath');

      final docSnapshot = await AppFirestore.tippingCollectionRef
          .doc(workerId)
          .collection("totalTipsCollectionRef")
          .doc(workerId)
          .get();

      if (!docSnapshot.exists) {
        debugPrint(
          '❌ No tips document found for worker: $workerId at path: $docPath',
        );
        return [];
      }

      debugPrint('✅ Tips document exists for worker: $workerId');

      final data = docSnapshot.data();
      if (data == null) {
        debugPrint('⚠️ Document exists but data is null for worker: $workerId');
        return [];
      }

      debugPrint('📄 Document data keys: ${data.keys.toList()}');

      if (data['tipData'] == null) {
        debugPrint(
          '⚠️ No tipData field found in document for worker: $workerId',
        );
        return [];
      }

      // Get the tipdata array field and convert to List<AllTipsModel>
      final List<dynamic> tipdataList = data['tipData'] as List<dynamic>;

      debugPrint('📊 tipData array length: ${tipdataList.length}');
      debugPrint('📊 tipData contents: $tipdataList');

      final List<AllTipsModel> tipsList = tipdataList
          .map(
            (tipJson) => AllTipsModel.fromJson(tipJson as Map<String, dynamic>),
          )
          .toList();

      debugPrint('✅ Fetched ${tipsList.length} tips for worker: $workerId');

      // Log each tip's details
      for (int i = 0; i < tipsList.length; i++) {
        final tip = tipsList[i];
        debugPrint(
          '  Tip $i: ID=${tip.id}, Amount=${tip.totalTipAmount}, PaymentMethod=${tip.paymentMethod}, CreatedAt=${tip.createdAt}',
        );
      }

      return tipsList;
    } catch (e) {
      debugPrint('❌ Error fetching tips: $e');
      return [];
    }
  }

  /// Fetches job categories from Firebase and returns them as a Map
  static Future<Map<String, Map<String, String>>> fetchJobCategories() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .get();

      final Map<String, Map<String, String>> categories = {};

      for (var doc in snapshot.docs) {
        final category = CategoryModel.fromQuerySnapshot(doc);

        // Use the category ID as the key, and create the localization map
        categories[category.id ?? doc.id] = {
          'en': category.name ?? '',
          'ar': category.name_ar ?? category.name ?? '',
          'ur': category.name_ur ?? category.name_ar ?? category.name ?? '',
        };
      }

      return categories;
    } catch (e) {
      debugPrint('Error fetching job categories: $e');
      return {};
    }
  }

  /// Get all tip payouts from all workers
  static Stream<List<Map<String, dynamic>>> getAllTipPayoutsHistory() {
    return FirebaseFirestore.instance
        .collectionGroup('tipPayoutCollectionsRef')
        .snapshots()
        .map((snapshot) {
          List<Map<String, dynamic>> allPayouts = [];

          for (var doc in snapshot.docs) {
            final data = doc.data();
            // Check for 'tipdata' (lowercase) as seen in Firestore, fallback to 'tipData'
            final tipDataField = data['tipdata'] ?? data['tipData'];

            if (tipDataField != null) {
              final List<dynamic> tipDataList = tipDataField as List<dynamic>;

              for (var tipJson in tipDataList) {
                final tipData = tipJson as Map<String, dynamic>;

                // Normalize data using AllTipsModel to ensure consistent fields (like 'Amount')
                final model = AllTipsModel.fromJson(tipData);
                final normalizedData = model.toJson();

                // Add worker ID from the document path
                final workerId = doc.reference.parent.parent?.id;
                allPayouts.add({...normalizedData, 'workerId': workerId});
              }
            }
          }

          // Sort by createdAt descending (most recent first)
          allPayouts.sort((a, b) {
            final aTime = a['createdAt'] as Timestamp?;
            final bTime = b['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          debugPrint(
            '✅ Fetched ${allPayouts.length} total tip payouts from all workers',
          );
          return allPayouts;
        });
  }

  /// Get tip payout history for a specific worker
  static Stream<List<AllTipsModel>> getTipPayoutsHistoryByWorkerId(
    String workerId,
  ) {
    return AppFirestore.tippingCollectionRef
        .doc(workerId)
        .collection('tipPayoutCollectionsRef')
        .doc(workerId)
        .snapshots()
        .map((docSnapshot) {
          List<AllTipsModel> payouts = [];

          if (!docSnapshot.exists) {
            debugPrint('❌ No tip payout history found for worker: $workerId');
            return payouts;
          }

          final data = docSnapshot.data();
          // Check for 'tipdata' (lowercase) as seen in Firestore, fallback to 'tipData' just in case
          final tipDataField = data?['tipdata'] ?? data?['tipData'];

          if (data == null || tipDataField == null) {
            debugPrint('⚠️ No tipdata found for worker: $workerId');
            return payouts;
          }

          final List<dynamic> tipDataList = tipDataField as List<dynamic>;

          for (var tipJson in tipDataList) {
            final tipData = tipJson as Map<String, dynamic>;
            payouts.add(AllTipsModel.fromJson(tipData));
          }

          // Sort by createdAt descending (most recent first)
          payouts.sort((a, b) {
            final aTime = a.createdAt;
            final bTime = b.createdAt;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          debugPrint(
            '✅ Fetched ${payouts.length} tip payouts for worker: $workerId',
          );
          return payouts;
        });
  }

  // ---------------------------------------------------------------------------------------------------------

  /// Stream for stats only (backward compatible)

  /// Build stats stream combining completed, latest, accepted, rating, and warranty claims
  static Stream<Map<String, dynamic>> _getStatsStream(String uid) {
    final completed = AppFirestore.bookingsCollectionRef
        .where('agent.uid', isEqualTo: uid)
        .where('bookingStatusCode', isEqualTo: 'C')
        .where('paymentCompleted', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .onErrorReturn(0);

    final latest = Rx.combineLatest2(
      AppFirestore.bookingsCollectionRef
          .where('agent.uid', isEqualTo: uid)
          .where('bookingStatusCode', isEqualTo: 'P')
          .snapshots(),
      getJobOffersStream(uid: uid),
      (QuerySnapshot bookingsSnapshot, List<JobOfferContainer> offers) {
        final Map<String, bool> uniqueMap = {};
        for (var doc in bookingsSnapshot.docs) {
          uniqueMap[doc.id] = true;
        }
        for (var offer in offers) {
          final id = offer.booking?.id ?? offer.requestId ?? offer.offerId;
          uniqueMap[id] = true;
        }
        return uniqueMap.length;
      },
    ).onErrorReturn(0);

    final accepted = AppFirestore.bookingsCollectionRef
        .where('agent.uid', isEqualTo: uid)
        .where('bookingStatusCode', isEqualTo: 'A')
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .onErrorReturn(0);

    // Must mirror the "Payment Pending" tab query in [getBookingsStream] exactly,
    // otherwise the dashboard counter and the list the technician lands on after
    // tapping it disagree. That tab covers both halves of the payment handover:
    // CP (technician finished, awaiting the customer's payment) and VP (customer
    // paid, awaiting the technician's verification).
    final paymentPending = AppFirestore.bookingsCollectionRef
        .where('agent.uid', isEqualTo: uid)
        .where('bookingStatusCode', whereIn: ['CP', 'VP'])
        .where('paymentCompleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        // A failure here (a missing Firestore index, most likely) would otherwise
        // be indistinguishable from "nothing pending" — the counter would just
        // read 0, which is exactly the symptom this query was fixed for. Log it
        // so the cause is visible while debugging.
        .doOnError(
          (e, _) => debugPrint('❌ paymentPending counter query failed: $e'),
        )
        .onErrorReturn(0);

    final Stream<double> rating = AppFirestore.bookingsCollectionRef
        .where('bookingStatusCode', isEqualTo: 'C')
        .where('agent.uid', isEqualTo: uid)
        .where('review', isNull: false)
        .snapshots()
        .map((snapshot) {
          final reviews = snapshot.docs
              .where((doc) => doc['review'] != null)
              .map((doc) => doc['review'])
              .toList();

          if (reviews.isEmpty) return 0.0;

          final ratings = reviews
              .map((review) => review['rating'])
              .where((rating) => rating != null)
              .map((rating) => (rating as num).toDouble())
              .toList();

          if (ratings.isEmpty) return 0.0;

          final sum = ratings.reduce((a, b) => a + b);
          return sum / ratings.length;
        })
        .onErrorReturn(0.0);

    final warrantyClaims = getWarrantyClaimRequestsStream(
      uid,
    ).map((claims) => claims.length).onErrorReturn(0);

    final wallet = UnifiedPayoutServices.getUnifiedWalletStream(
      uid,
    ).onErrorReturn(UnifiedWalletModel());

    return Rx.combineLatest7<
      int,
      int,
      int,
      int,
      double,
      int,
      UnifiedWalletModel,
      Map<String, dynamic>
    >(
      completed,
      latest,
      accepted,
      paymentPending,
      rating,
      warrantyClaims,
      wallet,
      (
        int completedCount,
        int latestCount,
        int acceptedCount,
        int paymentPendingCount,
        double avgRating,
        int warrantyClaimsCount,
        UnifiedWalletModel walletData,
      ) {
        debugPrint(
          '✅ Stats Combined - Completed: $completedCount, Latest: $latestCount, '
          'Accepted: $acceptedCount, Wallet: ${walletData.lifetimeTotal}',
        );
        return {
          'completed': completedCount,
          'latest': latestCount,
          'accepted': acceptedCount,
          'paymentPending': paymentPendingCount,
          'rating': avgRating.toStringAsFixed(1),
          'warrantyClaims': warrantyClaimsCount,
          'paidAmounts': walletData.lifetimeTotal ?? 0.0,
          'availableBalance': walletData.totalAvailableBalance ?? 0.0,
        };
      },
    );
  }

  /// Real-time stream for transactions
  static Stream<List<TransactionModel>> _getTransactionsRealTimeStream(
    String uid,
  ) {
    return AppFirestore.transactionsCollectionRef
        .where('workerId', isEqualTo: uid)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => TransactionModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        )
        .onErrorReturn(<TransactionModel>[]);
  }

  /// Real-time stream for tips
  static Stream<List<AllTipsModel>> _getTipsRealTimeStream(String uid) {
    return AppFirestore.tippingCollectionRef
        .doc(uid)
        .collection("totalTipsCollectionRef")
        .doc(uid)
        .snapshots()
        .map((docSnap) {
          if (!docSnap.exists) return <AllTipsModel>[];

          final data = docSnap.data();
          if (data?['tipData'] == null) return <AllTipsModel>[];

          final List<dynamic> tipdataList = data!['tipData'] as List<dynamic>;

          return tipdataList
              .map(
                (tipJson) =>
                    AllTipsModel.fromJson(tipJson as Map<String, dynamic>),
              )
              .toList();
        })
        .onErrorReturn(<AllTipsModel>[]);
  }

  /// Real-time stream for booking earnings (Full Service cost only)
  static Stream<double> _getBookingEarningsStream(String uid) {
    return AppFirestore.bookingsCollectionRef
        .where('agent.uid', isEqualTo: uid)
        .where('bookingStatusCode', isEqualTo: 'C')
        .snapshots()
        .map((snapshot) {
          double total = 0.0;
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final completionData = data['completionData'];
            // count only if mode is 1 (full service) and not inspection only
            if (completionData != null && completionData['mode'] == 1) {
              total += (completionData['totalCost'] as num?)?.toDouble() ?? 0.0;
            }
          }
          return total;
        })
        .onErrorReturn(0.0);
  }

  // ========== REFRESH CONTROL WITH STREAMS ==========

  /// StreamController to trigger manual refreshes
  final _dashboardRefreshController = StreamController<int>.broadcast();

  /// Get the refresh trigger stream
  Stream<int> get dashboardRefreshTrigger => _dashboardRefreshController.stream;

  /// Trigger manual refresh by adding a timestamp
  void triggerDashboardRefresh() {
    debugPrint('🔄 Manual dashboard refresh triggered');
    _dashboardRefreshController.add(DateTime.now().millisecondsSinceEpoch);
  }

  /// Dispose the refresh controller (call in app cleanup)
  void disposeDashboardRefresh() {
    _dashboardRefreshController.close();
  }

  /// Complete dashboard stream with manual refresh support
  static Stream<DashboardDataStream> getCompleteDashboardStreamWithRefresh(
    String uid,
    Stream<int> refreshTrigger,
  ) {
    debugPrint(
      '🚀 Setting up complete dashboard stream with refresh for: $uid',
    );

    return refreshTrigger
        .startWith(0) // Start immediately
        .switchMap((_) {
          debugPrint('📊 Dashboard data refresh initiated');
          return Rx.combineLatest5(
            _getStatsStream(uid),
            _getTransactionsRealTimeStream(uid),
            _getTipsRealTimeStream(uid),
            _getBookingEarningsStream(uid), // Was _getPaidAmountsStream
            _getLiveTipsStream(uid),
            (
              Map<String, dynamic> stats,
              List<TransactionModel> transactions,
              List<AllTipsModel> tips,
              double bookingEarnings,
              TippingModel liveTips,
            ) {
              debugPrint('📊 Dashboard stream updated - combining all data');

              return DashboardDataStream(
                stats: stats,
                totalEarnings: stats['paidAmounts'] ?? 0.0,
                transactions: transactions,
                tips: tips,
                paidAmounts: stats['paidAmounts'] ?? 0.0,
              );
            },
          );
        })
        .handleError((error) {
          debugPrint('❌ Dashboard stream error: $error');
          return DashboardDataStream(
            stats: {
              'completed': 0,
              'latest': 0,
              'accepted': 0,
              'rating': '0.0',
            },
            totalEarnings: 0.0,
            transactions: [],
            tips: [],
            paidAmounts: 0.0,
          );
        });
  }

  static Stream<TippingModel> _getLiveTipsStream(String uid) {
    final stream = AppFirestore.tippingCollectionRef.doc(uid).snapshots();
    return stream
        .map((snapshot) {
          final data = snapshot.data();
          if (!snapshot.exists || data == null) return TippingModel();
          return TippingModel.fromJson(data as Map<String, dynamic>);
        })
        .onErrorReturn(TippingModel());
  }

  /// Stream user data
  static Stream<UserModel?> getUserStream(String uid) {
    return AppFirestore.usersCollectionRef.doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return UserModel.fromJson(data as Map<String, dynamic>);
    });
  }

  static Stream<List<WarrantyModel>> getWarrantyClaimRequestsStream(
    String uid,
  ) {
    return AppFirestore.bookingsCollectionRef
        .where('bookingStatusCode', isEqualTo: 'C')
        .where('paymentCompleted', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final warrantyData = data['warranty'];
                if (warrantyData != null) {
                  return WarrantyModel.fromJson(
                    Map<String, dynamic>.from(warrantyData),
                  );
                }
                return null;
              })
              .where((warranty) {
                if (warranty == null) return false;

                // Include 'R' (Requested - if somehow pre-assigned) and 'S' (Scheduled/Assigned by Admin)
                if (warranty.warrantyStatusCode != 'R' &&
                    warranty.warrantyStatusCode != 'S') {
                  return false;
                }

                // Check if technician is assigned to this warranty
                bool isAssigned =
                    warranty.assignedTechnician?.uid == uid ||
                    warranty.assignedTechnicianId == uid;
                if (!isAssigned) return false;

                // If rejectedTechnicians is null or empty, include the request
                if (warranty.rejectedTechnicians == null ||
                    warranty.rejectedTechnicians!.isEmpty) {
                  return true;
                }

                // Otherwise exclude if your UID is in the list
                final alreadyRejected = warranty.rejectedTechnicians!.any(
                  (rejectedTech) =>
                      rejectedTech.uid != null && rejectedTech.uid == uid,
                );
                return !alreadyRejected;
              })
              .map((warranty) => warranty!)
              .toList(),
        );
  }

  static Stream<List<TransactionModel>> getAllTransactionsStream() {
    return AppFirestore.transactionsCollectionRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => TransactionModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
        });
  }

  static Stream<Map<String, dynamic>> getAllCustomersAndTechniciansStream() {
    final customer = AppServices.getAllCustomersStream();
    final technicians = AppServices.getAllAgentsStream();

    return Rx.combineLatest2(customer, technicians, (
      List customers,
      List technicians,
    ) {
      return {'customers': customers, 'technicians': technicians};
    });
  }

  static Future<BookingModel?> getBooking(String bookingId) {
    return AppFirestore.bookingsCollectionRef
        .doc(bookingId)
        .get()
        .then((doc) => BookingModel.fromDocumentSnapshot(doc));
  }

  static void rejectWarrantyClaim({
    required String bookingId,
    String? technicianUid,
    String? technicianName,
    String? reason,
  }) async {
    final rejectedTech = {
      'uid': technicianUid,
      'name': technicianName,
      'reason': reason,
      'rejectedAt': Timestamp.fromDate(DateTime.now()),
    };

    await AppFirestore.bookingsCollectionRef.doc(bookingId).update({
      'warranty.assignedTechnician': null,
      'warranty.assignedTechnicianId': "",
      'warranty.warrantyStatusCode': 'R',
      'warranty.availability': true,
      'warranty.rejectedTechnicians': FieldValue.arrayUnion([rejectedTech]),
      "warranty.updatedAt": FieldValue.serverTimestamp(),
    });
  }

  static Stream<AdminDashboardData> getAdminDashboardStream() {
    final pendingBookings = AppFirestore.bookingsCollectionRef
        .where('bookingStatusCode', isEqualTo: 'P')
        .snapshots()
        .map((s) => s.docs.map((doc) => doc.id).toList())
        .onErrorReturn([]);

    // Expired requests have to drop out of the count on the same rule the
    // Pending tab hides them on, ticker included - otherwise the tile keeps
    // reporting a request the tab will not show, for as long as it takes the
    // cleanup cron to close it server-side (and forever if that never runs).
    final rawBookingRequests =
        Rx.combineLatest2(
          AppFirestore.bookingRequestsCollectionRef
              .where('status', whereIn: ['pending', 'searching'])
              .snapshots(),
          _expiryTicker(),
          (snapshot, _) => snapshot,
        ).map((s) {
          final now = TimeService.now;
          return s.docs
              .where(
                (doc) => isBookingRequestLive(
                  doc.data() as Map<String, dynamic>,
                  now: now,
                ),
              )
              .map((doc) => doc.id)
              .toList();
        }).onErrorReturn(<String>[]);

    final pending = Rx.combineLatest2(
      pendingBookings,
      rawBookingRequests,
      (List<String> b, List<String> br) {
        final Set<String> uniqueIds = {};
        uniqueIds.addAll(b);
        uniqueIds.addAll(br);
        return uniqueIds.length;
      },
    ).onErrorReturn(0);

    final jobRequests = Stream.value(0);

    final assigned = AppFirestore.bookingsCollectionRef
        .where('bookingStatusCode', isEqualTo: 'A')
        .snapshots()
        .map((s) => s.docs.length)
        .onErrorReturn(0);

    final completed = AppFirestore.bookingsCollectionRef
        .where('bookingStatusCode', isEqualTo: 'C')
        .where('paymentCompleted', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.length)
        .onErrorReturn(0);

    final warrantyClaims = AppFirestore.bookingsCollectionRef
        .where('bookingStatusCode', isEqualTo: 'C')
        .where('paymentCompleted', isEqualTo: true)
        .snapshots()
        .map((s) {
          return s.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            final warranty = data?['warranty'] as Map<String, dynamic>?;
            if (warranty == null) return false;
            final statusCode = warranty['warrantyStatusCode'] as String?;
            return statusCode == 'R' || statusCode == 'S';
          }).length;
        })
        .onErrorReturn(0);

    final customers = AppFirestore.customersCollectionRef
        .snapshots()
        .map((s) {
          return s.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['role'] == 'customer' &&
                data['uid'] != null &&
                data['uid'].toString().isNotEmpty;
          }).length;
        })
        .onErrorReturn(0);

    final technicians = AppFirestore.usersCollectionRef
        .snapshots()
        .map((s) {
          return s.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['isAdmin'] != true &&
                data['uid'] != null &&
                data['uid'].toString().isNotEmpty;
          }).length;
        })
        .onErrorReturn(0);

    final completedBookings = AppFirestore.bookingsCollectionRef
        .where('paymentCompleted', isEqualTo: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map((doc) => BookingModel.fromDocumentSnapshot(doc))
              .toList(),
        )
        .onErrorReturn(<BookingModel>[]);

    return Rx.combineLatest8<
      int,
      int,
      int,
      int,
      int,
      int,
      int,
      List<BookingModel>,
      AdminDashboardData
    >(
      pending,
      assigned,
      completed,
      warrantyClaims,
      customers,
      technicians,
      jobRequests,
      completedBookings,
      (p, a, c, w, cust, tech, jr, bookings) {
        Map<String, double> revenue = {};
        Map<String, double> rev7 = {};
        Map<String, double> rev30 = {};
        Map<String, double> rev12 = {};
        double totalRev = 0.0;
        List<Map<String, dynamic>> rawData = [];

        // Revenue is bucketed by Saudi day and month, so the same booking
        // lands in the same bucket for every admin regardless of where they are.
        final now = KsaTime.now;
        final today = KsaTime.today;

        // Prepare keys
        final last6Months = List.generate(6, (i) {
          return DateFormat('MMM yyyy').format(DateTime(now.year, now.month - i, 1));
        }).reversed.toList();

        final last12Months = List.generate(12, (i) {
          return DateFormat('MMM yyyy').format(DateTime(now.year, now.month - i, 1));
        }).reversed.toList();

        final last30Days = List.generate(30, (i) {
          return DateFormat('dd MMM').format(today.subtract(Duration(days: i)));
        }).reversed.toList();

        final last7Days = List.generate(7, (i) {
          return DateFormat('dd MMM').format(today.subtract(Duration(days: i)));
        }).reversed.toList();

        for (var m in last6Months) revenue[m] = 0.0;
        for (var m in last12Months) rev12[m] = 0.0;
        for (var d in last30Days) rev30[d] = 0.0;
        for (var d in last7Days) rev7[d] = 0.0;

        for (var booking in bookings) {
          final instant =
              booking.paymentVerifiedAt?.toDate() ??
              booking.paymentCompletedAt?.toDate() ??
              booking.completedAt?.toDate();
          // Label against the KSA wall clock to match the bucket keys above.
          final date = instant == null ? null : KsaTime.fromInstant(instant);
          if (date != null) {
            final monthStr = DateFormat('MMM yyyy').format(date);
            final dayStr = DateFormat('dd MMM').format(date);
            
            final amount =
                (booking.completionData?.totalCost ?? 0.0) +
                booking.service.getDiscountedPrice(
                  booking.effectiveInspectionFee,
                );

            totalRev += amount;
            rawData.add({'date': date, 'amount': amount});

            if (revenue.containsKey(monthStr)) {
              revenue[monthStr] = (revenue[monthStr] ?? 0.0) + amount;
            }
            if (rev12.containsKey(monthStr)) {
              rev12[monthStr] = (rev12[monthStr] ?? 0.0) + amount;
            }
            if (rev30.containsKey(dayStr)) {
              rev30[dayStr] = (rev30[dayStr] ?? 0.0) + amount;
            }
            if (rev7.containsKey(dayStr)) {
              rev7[dayStr] = (rev7[dayStr] ?? 0.0) + amount;
            }
          }
        }

        return AdminDashboardData(
          pendingCount: p + jr,
          assignedCount: a,
          completedCount: c,
          warrantyClaimsCount: w,
          customerCount: cust,
          technicianCount: tech,
          monthlyRevenue: revenue,
          revenue7Days: rev7,
          revenue30Days: rev30,
          revenue12Months: rev12,
          totalRevenue: totalRev,
          rawRevenueData: rawData,
        );
      },
    );
  }

  static Future<bool> checkCustomerPhoneNumberAlredyExist(
    String phoneNumber, {
    String? excludeUid,
  }) async {
    try {
      String normalizedPhoneNumber = phoneNumber.replaceAll(
        RegExp(r'[^\d+]'),
        '',
      );
      String convertedNumber = "+966${normalizedPhoneNumber.substring(1)}";

      // Query technicians with the phone number (converted format)
      var technicianQuery = AppFirestore.usersCollectionRef.where(
        'phone',
        isEqualTo: convertedNumber,
      );

      // If excludeUid is provided, exclude the current user
      if (excludeUid != null) {
        technicianQuery = technicianQuery.where(
          'uid',
          isNotEqualTo: excludeUid,
        );
      }

      final result = await technicianQuery.limit(1).get();
      if (result.docs.isNotEmpty) {
        return true;
      }

      // Try with original phoneNumber format
      var technicianQueryOriginal = AppFirestore.usersCollectionRef.where(
        'phone',
        isEqualTo: phoneNumber,
      );

      if (excludeUid != null) {
        technicianQueryOriginal = technicianQueryOriginal.where(
          'uid',
          isNotEqualTo: excludeUid,
        );
      }

      final resultOriginal = await technicianQueryOriginal.limit(1).get();
      return resultOriginal.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> sendCounterOffer({
    required String bookingId,
    String? offerId,
    required String proposedBy,
    required String proposedByUid,
    required String proposedByName,
    required Timestamp proposedTime,
    required String customerId,
  }) async {
    try {
      // If bookingId might be a request ID, resolve from the offer
      String resolvedBookingId = bookingId;
      if (offerId != null) {
        final offerDoc = await AppFirestore.jobOffersCollectionRef
            .doc(offerId)
            .get();
        if (offerDoc.exists) {
          final data = offerDoc.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey('bookingId')) {
            resolvedBookingId = data['bookingId'] ?? bookingId;
          }
        }
      }

      // Create counter offer document
      final docRef = AppFirestore.counterOffersCollectionRef.doc();
      final counterOffer = CounterOfferModel(
        id: docRef.id,
        bookingId: resolvedBookingId,
        proposedBy: proposedBy,
        proposedByUid: proposedByUid,
        proposedByName: proposedByName,
        proposedTime: proposedTime,
        status: 'pending',
        createdAt: Timestamp.now(),
      );

      if (offerId != null) {
        await AppFirestore.jobOffersCollectionRef.doc(offerId).update({
          'proposedTime': proposedTime,
          'status': 'counter_offered',
          'counterOfferedBy': proposedBy,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Update booking with activeCounterOffer
      Map<String, dynamic> updateData = {
        'activeCounterOffer': counterOffer.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Set counterProposalStartedAt if not already set by checking multiple collections
      final bookingDoc = await AppFirestore.bookingsCollectionRef
          .doc(resolvedBookingId)
          .get();
      if (bookingDoc.exists) {
        final data = bookingDoc.data() as Map<String, dynamic>?;
        if (data?['counterProposalStartedAt'] == null) {
          updateData['counterProposalStartedAt'] = FieldValue.serverTimestamp();
        }
        await AppFirestore.bookingsCollectionRef
            .doc(resolvedBookingId)
            .update(updateData);
      } else {
        // Fallback to job_requests
        final jobReqDoc = await AppFirestore.jobRequestsCollectionRef
            .doc(resolvedBookingId)
            .get();
        if (jobReqDoc.exists) {
          final data = jobReqDoc.data() as Map<String, dynamic>?;
          if (data?['counterProposalStartedAt'] == null) {
            updateData['counterProposalStartedAt'] =
                FieldValue.serverTimestamp();
          }
          await AppFirestore.jobRequestsCollectionRef
              .doc(resolvedBookingId)
              .update(updateData);
        } else {
          // Fallback to booking_request
          final bookingReqDoc = await AppFirestore.bookingRequestsCollectionRef
              .doc(resolvedBookingId)
              .get();
          if (bookingReqDoc.exists) {
            final data = bookingReqDoc.data() as Map<String, dynamic>?;
            if (data?['counterProposalStartedAt'] == null) {
              updateData['counterProposalStartedAt'] =
                  FieldValue.serverTimestamp();
            }
            await AppFirestore.bookingRequestsCollectionRef
                .doc(resolvedBookingId)
                .update(updateData);
          } else {
            // Document doesn't exist anywhere we expect it to
            debugPrint(
              'Warning: resolvedBookingId $resolvedBookingId not found in bookings, job_requests, or booking_request collections',
            );
          }
        }
      }

      // Write to counter_offers collection (triggers Cloud Function notifications)
      await docRef.set(counterOffer.toMap());

      // Send notification to customer
      if (customerId.isNotEmpty) {
        await _recordCustomerNotification(
          customerId: customerId,
          titleEn: 'Update Regarding Your Request',
          titleAr: 'تحديث بخصوص طلبك',
          bodyEn: 'Technician has proposed a new time for your booking.',
          bodyAr: 'اقترح الفني موعداً جديداً لحجزك.',
          type: 'counter_offer',
          data: {'bookingId': resolvedBookingId, 'offerId': offerId},
        );
      }

      return true;
    } catch (e) {
      debugPrint('Error sending counter offer: $e');
      return false;
    }
  }

  static Future<void> _recordCustomerNotification({
    required String customerId,
    required String titleEn,
    required String titleAr,
    required String bodyEn,
    required String bodyAr,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await AppFirestore.customersCollectionRef
          .doc(customerId)
          .collection('notifications')
          .add({
            'titleEn': titleEn,
            'titleAr': titleAr,
            'bodyEn': bodyEn,
            'bodyAr': bodyAr,
            'type': type,
            'data': data,
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
          });
    } catch (e) {
      debugPrint('Error recording customer notification: $e');
    }
  }

  static Stream<List<WarrantyModel>> getAllWarrantyClaimRequestsStream() {
    return AppFirestore.bookingsCollectionRef
        .where("bookingStatusCode", isEqualTo: "C")
        .where("paymentCompleted", isEqualTo: true)
        .where("warranty.availability", isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          console.log('Total docs found: ${snapshot.docs.length}');
          return snapshot.docs
              .map((doc) {
                try {
                  final data = doc.data() as Map<String, dynamic>;
                  console.log('Processing doc ${doc.id}');

                  // Check if warranty field exists
                  if (data['warranty'] == null) {
                    console.log('Skipping doc ${doc.id}: warranty is null');
                    return null;
                  }

                  return WarrantyModel.fromJson(
                    data['warranty'] as Map<String, dynamic>,
                  );
                } catch (e) {
                  debugPrint('Error processing doc ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<WarrantyModel>() // Filters out nulls
              .toList();
        });
  }

  static Stream<List<JobOfferContainer>> getJobOffersStream({
    String? uid,
    bool isAdmin = false,
  }) {
    final userId = uid ?? LocalStore.getUID();
    if (!isAdmin && (userId == null || userId.isEmpty)) return Stream.value([]);

    var query = AppFirestore.jobOffersCollectionRef.where(
      'status',
      whereIn: [
        'pending',
        'counter_offered',
        'customer_counter_offered',
        'accepted_by_technician',
      ],
    );

    if (!isAdmin) {
      query = query.where('technicianId', isEqualTo: userId);
    }

    final firestoreStream = query.snapshots();

    // Combine with a periodic timer to force re-evaluation of 'expiresAt' every 10s
    // Added .startWith(0) to ensure the stream emits immediately on subscription
    final timerStream = Stream.periodic(
      const Duration(seconds: 10),
      (i) => i,
    ).startWith(0);

    return Rx.combineLatest2(
      firestoreStream,
      timerStream,
      (snapshot, _) => snapshot,
    ).asyncMap((snapshot) async {
      final now = TimeService.now;

      final activeOffers = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final expiresAt = data['expiresAt'] as Timestamp?;
        final status = data['status'] as String?;
        final isExpired = expiresAt != null && expiresAt.toDate().isBefore(now);
        final isAcceptedByMe = status == 'accepted_by_technician';
        return !isExpired || isAcceptedByMe;
      }).toList();

      if (activeOffers.isEmpty) return [];

      final List<Future<JobOfferContainer?>> fetchFutures = activeOffers.map((
        doc,
      ) async {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final bookingId = data['bookingId'];
          final requestId = data['requestId'];

          if (bookingId != null) {
            final booking = await getBookingById(bookingId);
            if (booking != null) {
              if (booking.bookingStatusCode == 'P' ||
                  (booking.bookingStatusCode == 'R' &&
                      booking.rejectedBy != 'Admin') ||
                  booking.bookingStatusCode == 'A') {
                // If booking is 'A' (Assigned), it should only show for the assigned technician
                if (booking.bookingStatusCode == 'A' &&
                    booking.agent?.uid != userId) {
                  return null;
                }

                return JobOfferContainer(
                  offerId: doc.id,
                  booking: booking,
                  offerData: data,
                );
              }
            } else {
              // The booking document doesn't exist in bookings collection yet (Manual Booking Request).
              // We render this request card using the offerData.
              return JobOfferContainer(
                offerId: doc.id,
                requestId: requestId,
                offerData: data,
              );
            }
          } else if (requestId != null) {
            // For broadcast requests, we can either fetch JobRequest or use offerData
            // User requested showing customer name, location, distance.
            // These are in offerData.
            return JobOfferContainer(
              offerId: doc.id,
              requestId: requestId,
              offerData: data,
            );
          }
        } catch (e) {
          debugPrint('Error fetching data for offer ${doc.id}: $e');
        }
        return null;
      }).toList();

      final results = await Future.wait(fetchFutures);
      return results.whereType<JobOfferContainer>().toList();
    });
  }

  static Future<void> acceptJobOffer({
    String? bookingId,
    String? requestId,
    required String offerId,
    required UserModel technician,
  }) async {
    final offerRef = AppFirestore.jobOffersCollectionRef.doc(offerId);

    if (requestId != null) {
      // It's a broadcast request - just signify interest.
      //
      // The customer is not written to from here. For a rebook, their
      // "requested technician has accepted your booking request" notification
      // is raised by the `onManualJobOfferUpdated` Cloud Function off this same
      // status transition, so it arrives as an actual push on their device
      // instead of only appearing in the in-app list the next time they open it.
      await offerRef.update({
        'status': 'accepted_by_technician',
        'acceptedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    if (bookingId == null) throw Exception('No booking or request ID provided');

    final bookingRef = AppFirestore.bookingsCollectionRef.doc(bookingId);
    bool wasAutoAssigned = false;

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final bookingSnapshot = await transaction.get(bookingRef);
      final offerSnapshot = await transaction.get(offerRef);

      if (!bookingSnapshot.exists) throw Exception('Booking not found');
      if (!offerSnapshot.exists) throw Exception('Offer not found');

      final bookingData = bookingSnapshot.data() as Map<String, dynamic>;
      final offerData = offerSnapshot.data() as Map<String, dynamic>;

      if (bookingData['bookingStatusCode'] != 'P') {
        throw Exception('Booking is already assigned or cancelled');
      }

      if (bookingData['agent'] != null &&
          bookingData['agent']['uid'] != null &&
          (bookingData['agent']['uid'] as String).isNotEmpty &&
          bookingData['agent']['uid'] != technician.uid) {
        throw Exception('Booking is already assigned to another technician');
      }

      if (offerData['status'] != 'pending') {
        throw Exception('Offer is no longer available');
      }

      final bool isAutoAssignment = bookingData['autoAssignmentStatus'] != null;

      if (isAutoAssignment) {
        wasAutoAssigned = true;
        // Auto-assignment booking: Assign technician immediately
        transaction.update(bookingRef, {
          'bookingStatusCode': 'A',
          'agent': {
            'uid': technician.uid,
            'name': technician.name,
            'phone': technician.phone,
            'profileUrl': technician.profileUrl,
          },
          'assignedAt': FieldValue.serverTimestamp(),
          'autoAssignmentStatus': 'accepted',
        });

        transaction.update(offerRef, {
          'status': 'accepted',
          'acceptedAt': FieldValue.serverTimestamp(),
        });

        // Also update the auto-assignment request status
        final autoReqRef = AppFirestore.autoAssignmentRequestsCollectionRef.doc(
          bookingId,
        );
        transaction.update(autoReqRef, {
          'status': 'A',
          'agent': {
            'uid': technician.uid,
            'name': technician.name,
            'phone': technician.phone,
            'profileUrl': technician.profileUrl,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Not an auto-assignment booking: Just record acceptance
        transaction.update(offerRef, {
          'status': 'accepted_by_technician',
          'acceptedAt': FieldValue.serverTimestamp(),
        });
      }
    });

    if (wasAutoAssigned) {
      // Clean up lingering job offers for this booking
      try {
        final snapshot = await AppFirestore.jobOffersCollectionRef
            .where('bookingId', isEqualTo: bookingId)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final batch = FirebaseFirestore.instance.batch();
          int deletedCount = 0;
          for (var doc in snapshot.docs) {
            if (doc.id != offerId) {
              batch.delete(doc.reference);
              deletedCount++;
            }
          }
          if (deletedCount > 0) {
            await batch.commit();
            debugPrint(
              'Cleaned up $deletedCount lingering job offers for booking $bookingId',
            );
          }
        }
      } catch (e) {
        debugPrint('Error cleaning up lingering job offers: $e');
      }
    }

    try {
      final bookingDoc = await AppFirestore.bookingsCollectionRef
          .doc(bookingId)
          .get();
      if (bookingDoc.exists) {
        final bookingData = bookingDoc.data() as Map<String, dynamic>;
        final customerId = bookingData['customerId'];
        if (customerId != null) {
          await _recordCustomerNotification(
            customerId: customerId,
            titleEn: 'Technician Assigned!',
            titleAr: 'تم تعيين الفني!',
            bodyEn: '${technician.name} has been assigned to your booking.',
            bodyAr: 'تم تعيين ${technician.name} لطلبك.',
            type: 'booking_assigned',
            data: {'bookingId': bookingId},
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending acceptance notification: $e');
    }
  }

  /// Declines a job offer.
  ///
  /// [autoDeclined] marks a decline the technician never actually made - the
  /// offer's countdown simply ran out. The distinction is written to the offer
  /// because the customer must not be told a rebook was "rejected" when their
  /// technician only failed to answer; `onManualJobOfferUpdated` reads this
  /// flag and stays silent for a timeout.
  static Future<void> declineJobOffer(
    String offerId, {
    bool autoDeclined = false,
  }) async {
    try {
      final offerDoc = await AppFirestore.jobOffersCollectionRef
          .doc(offerId)
          .get();
      if (!offerDoc.exists) return;

      final batch = FirebaseFirestore.instance.batch();

      batch.update(AppFirestore.jobOffersCollectionRef.doc(offerId), {
        'status': 'declined',
        'declinedAt': FieldValue.serverTimestamp(),
        'autoDeclined': autoDeclined,
      });

      await batch.commit();
    } catch (e) {
      debugPrint('Error declining job offer: $e');
      rethrow;
    }
  }

  static Future<String?> getPendingJobOfferId(String bookingId) async {
    String userId = LocalStore.getUID() ?? '';
    if (userId.isEmpty) return null;

    final snapshot = await AppFirestore.jobOffersCollectionRef
        .where('bookingId', isEqualTo: bookingId)
        .where('technicianId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final expiresAt = snapshot.docs.first['expiresAt'] as Timestamp;
      if (expiresAt.toDate().isAfter(TimeService.now)) {
        return snapshot.docs.first.id;
      }
    }
    return null;
  }
}

class JobOfferContainer {
  final String offerId;
  final String? requestId;
  final BookingModel? booking;
  final Map<String, dynamic> offerData;

  JobOfferContainer({
    required this.offerId,
    this.requestId,
    this.booking,
    required this.offerData,
  });
}

class DashboardDataStream {
  final Map<String, dynamic> stats;
  final double totalEarnings;
  final List<TransactionModel> transactions;
  final List<AllTipsModel> tips;
  final double paidAmounts;

  const DashboardDataStream({
    required this.stats,
    required this.totalEarnings,
    required this.transactions,
    required this.tips,
    required this.paidAmounts,
  });

  // Helper to get specific stats
  int get completedBookings => (stats['completed'] as int?) ?? 0;
  int get latestRequests => (stats['latest'] as int?) ?? 0;
  int get acceptedBookings => (stats['accepted'] as int?) ?? 0;
  double get rating =>
      double.tryParse(stats['rating']?.toString() ?? '0') ?? 0.0;
}
