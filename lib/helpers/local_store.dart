import 'package:aboglumbo_bbk_panel/main.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/models/admin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LocalStore {
  // ============================================
  // UID Management
  // ============================================
  static Future<void> putUID(String uid) {
    // Also store as last valid UID for biometric authentication
    MyApp.box.put('last_valid_uid', uid);
    return MyApp.box.put('uid', uid);
  }

  static String? getUID() {
    return MyApp.box.get('uid');
  }

  // Get the last valid UID (for biometric auth after logout)
  static String? getLastValidUID() {
    return MyApp.box.get('last_valid_uid');
  }

  // clear uid
  static Future<void> clearUID() {
    return MyApp.box.delete('uid');
  }

  static Future<void> clearLastValidUID() {
    return MyApp.box.delete('last_valid_uid');
  }

  // ============================================
  // Logout Status
  // ============================================
  static Future<void> putlogoutStatus(bool isLoggedOut) async {
    await MyApp.box.put('is_logged_out', isLoggedOut);
  }

  static bool getLogoutStatus() {
    return MyApp.box.get('is_logged_out', defaultValue: false) ?? false;
  }

  static Future<void> clearLogoutStatus() async {
    await MyApp.box.delete('is_logged_out');
  }

  // ============================================
  // Remember Me Feature
  // ============================================
  static Future<void> putRememberMe(bool rememberMe) async {
    return MyApp.box.put('remember_me', rememberMe);
  }

  static bool getRememberMe() {
    return MyApp.box.get('remember_me', defaultValue: false) ?? false;
  }

  static Future<void> clearRememberMe() async {
    return MyApp.box.delete('remember_me');
  }

  // ============================================
  // Phone Number Storage (NEW - for phone authentication)
  // ============================================

  /// Save phone number for Remember Me feature
  static Future<void> rememberPhone(String phone) async {
    await MyApp.box.put('remember_phone', phone);
    await MyApp.box.flush();
  }

  /// Get remembered phone number
  static String? getRememberedPhone() {
    return MyApp.box.get('remember_phone');
  }

  /// Clear remembered phone number
  static Future<void> clearRememberedPhone() async {
    await MyApp.box.delete('remember_phone');
    await MyApp.box.flush();
  }

  // ============================================
  // Language Preference
  // ============================================
  static Future<String> putUserlanguage(String lang) async {
    await MyApp.box.put('user_language', lang);
    await MyApp.box.flush();
    return lang;
  }

  static String getUserlanguage() {
    return MyApp.box.get('user_language', defaultValue: 'en');
  }

  // ============================================
  // Biometric Authentication (per-user UID)
  // ============================================
  static Future<bool> setBiometricAuthEnabled(
    bool isEnabled,
    String uid,
  ) async {
    await MyApp.box.put('biometric_auth_enabled_$uid', isEnabled);
    await MyApp.box.flush();
    return true;
  }

  static bool getBiometricAuthEnabled(String uid) {
    return MyApp.box.get('biometric_auth_enabled_$uid', defaultValue: false) ??
        false;
  }

  static Future<void> clearBiometricAuthEnabled(String uid) async {
    await MyApp.box.delete('biometric_auth_enabled_$uid');
  }


  // ============================================
  // Active Booking Tracking
  // ============================================
  static Future<void> setActiveBookingId(String bookingId) async {
    await MyApp.box.put('active_booking_id', bookingId);
    await MyApp.box.flush();
  }

  static String? getActiveBookingId() {
    return MyApp.box.get('active_booking_id');
  }

  static Future<void> clearActiveBookingId() async {
    await MyApp.box.delete('active_booking_id');
  }

  // ============================================
  // Role Preference (Admin/Technician Mode)
  // ============================================

  /// Save user's role preference (admin or technician)
  static Future<void> setRolePreference(String role) async {
    await MyApp.box.put('role_preference', role);
    await MyApp.box.flush();
  }

  /// Get user's role preference
  static Future<String?> getRolePreference() async {
    return MyApp.box.get('role_preference');
  }

  /// Clear role preference
  static Future<void> clearRolePreference() async {
    await MyApp.box.delete('role_preference');
    await MyApp.box.flush();
  }

  // ============================================
  // Welcome Modal Tracking
  // ============================================

  /// Check if welcome modal has been shown for this user
  static bool getWelcomeModalShown(String uid) {
    return MyApp.box.get('welcome_modal_shown_$uid', defaultValue: false) ??
        false;
  }

  /// Mark welcome modal as shown for this user
  static Future<void> setWelcomeModalShown(String uid, bool shown) async {
    await MyApp.box.put('welcome_modal_shown_$uid', shown);
    await MyApp.box.flush();
  }

  // ============================================
  // User Data Cache (for offline/quick access)
  // ============================================

  /// Store user data with Timestamp conversion for Hive compatibility
  static Future<void> storeUserData(UserModel user) async {
    final Map<String, dynamic> userData = user.toJson();

    // Convert Timestamp objects to milliseconds for Hive storage
    final Map<String, dynamic> convertedData = _convertTimestampsToMillis(
      userData,
    );

    await MyApp.box.put('cached_user_data', convertedData);
    await MyApp.box.flush();
  }

  /// Get cached user data with Timestamp reconstruction
  static UserModel? getCachedUserData() {
    final userData = MyApp.box.get('cached_user_data');
    if (userData != null && userData is Map) {
      try {
        final Map<String, dynamic> dataMap = Map<String, dynamic>.from(
          userData,
        );

        // Convert milliseconds back to Timestamp objects
        final Map<String, dynamic> convertedData = _convertMillisToTimestamps(
          dataMap,
        );

        return UserModel.fromJson(convertedData);
      } catch (e) {
        debugPrint('Error parsing cached user data: $e');
        return null;
      }
    }
    return null;
  }

  static Future<void> clearCachedUserData() async {
    await MyApp.box.delete('cached_user_data');
    await MyApp.box.flush();
  }

  /// Store admin data
  static Future<void> storeAdminData(AdminModel admin) async {
    final Map<String, dynamic> adminData = admin.toJson();
    final Map<String, dynamic> convertedData = _convertTimestampsToMillis(
      adminData,
    );
    await MyApp.box.put('cached_admin_data', convertedData);
    await MyApp.box.flush();
  }

  /// Get cached admin data
  static AdminModel? getCachedAdminData() {
    final adminData = MyApp.box.get('cached_admin_data');
    if (adminData != null && adminData is Map) {
      try {
        final Map<String, dynamic> dataMap = Map<String, dynamic>.from(
          adminData,
        );
        final Map<String, dynamic> convertedData = _convertMillisToTimestamps(
          dataMap,
        );
        return AdminModel.fromJson(convertedData);
      } catch (e) {
        debugPrint('Error parsing cached admin data: $e');
        return null;
      }
    }
    return null;
  }

  static Future<void> clearCachedAdminData() async {
    await MyApp.box.delete('cached_admin_data');
    await MyApp.box.flush();
  }

  // ============================================
  // Helper Methods for Timestamp Conversion
  // ============================================

  /// Convert Timestamp and GeoPoint objects to serializable formats recursively
  static Map<String, dynamic> _convertTimestampsToMillis(
    Map<String, dynamic> data,
  ) {
    final Map<String, dynamic> converted = {};

    data.forEach((key, value) {
      if (value is Timestamp) {
        // Convert Timestamp to milliseconds
        converted[key] = value.millisecondsSinceEpoch;
      } else if (value is GeoPoint) {
        // Convert GeoPoint to Map
        converted[key] = {
          '_type': 'GeoPoint',
          'latitude': value.latitude,
          'longitude': value.longitude,
        };
      } else if (value is Map) {
        // Recursively convert nested maps
        converted[key] = _convertTimestampsToMillis(
          Map<String, dynamic>.from(value),
        );
      } else if (value is List) {
        // Handle lists
        converted[key] = value.map((item) {
          if (item is Timestamp) {
            return item.millisecondsSinceEpoch;
          } else if (item is GeoPoint) {
            return {
              '_type': 'GeoPoint',
              'latitude': item.latitude,
              'longitude': item.longitude,
            };
          } else if (item is Map) {
            return _convertTimestampsToMillis(Map<String, dynamic>.from(item));
          }
          return item;
        }).toList();
      } else {
        converted[key] = value;
      }
    });

    return converted;
  }

  /// Convert milliseconds and serialized GeoPoints back to original types recursively
  static Map<String, dynamic> _convertMillisToTimestamps(
    Map<String, dynamic> data,
  ) {
    final Map<String, dynamic> converted = {};

    // Known timestamp fields in models
    final List<String> timestampFields = [
      'createdAt',
      'updatedAt',
      'lastLogin',
      'dateOfBirth',
      'registrationDate',
      'grantedAdminAt',
      'lastBonusDate',
    ];

    data.forEach((key, value) {
      if (value is int && timestampFields.contains(key)) {
        // Convert milliseconds back to Timestamp
        converted[key] = Timestamp.fromMillisecondsSinceEpoch(value);
      } else if (value is Map && value['_type'] == 'GeoPoint') {
        // Convert Map back to GeoPoint
        converted[key] = GeoPoint(
          (value['latitude'] as num).toDouble(),
          (value['longitude'] as num).toDouble(),
        );
      } else if (value is Map) {
        // Recursively convert nested maps
        converted[key] = _convertMillisToTimestamps(
          Map<String, dynamic>.from(value),
        );
      } else if (value is List) {
        // Handle lists
        converted[key] = value.map((item) {
          if (item is Map && item['_type'] == 'GeoPoint') {
            return GeoPoint(
              (item['latitude'] as num).toDouble(),
              (item['longitude'] as num).toDouble(),
            );
          } else if (item is Map) {
            return _convertMillisToTimestamps(Map<String, dynamic>.from(item));
          }
          return item;
        }).toList();
      } else {
        converted[key] = value;
      }
    });

    return converted;
  }

  // ============================================
  // Utility: Clear All Auth Data on Logout
  // ============================================
  static Future<void> clearAllAuthData() async {
    await putlogoutStatus(true);
    await clearUID();
    await clearCachedUserData();
    await clearCachedAdminData();
    await clearActiveBookingId();
    // await clearLastValidUID(); // Keep last valid UID for biometric re-login after logout

    // ✅ FIXED: Only clear phone if Remember Me is disabled
    if (!getRememberMe()) {
      await clearRememberedPhone();
      await clearRememberMe();
    }

    await MyApp.box.flush();
  }
}
