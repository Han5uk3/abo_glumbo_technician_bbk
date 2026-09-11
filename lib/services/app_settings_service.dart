import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Reads remote feature flags from `app_settings/technician_app_v1`.
///
/// Flags are controlled server-side so options can be toggled without a new
/// app release.
class AppSettingsService {
  /// Settings document for this app.
  static const String docId = 'technician_app_v1';

  /// Flag deciding whether the "Delete account" option is offered.
  static const String showDeleteAccountField = 'showDeleteAccount';

  static DocumentReference<Object?> get _docRef =>
      AppFirestore.appSettingsCollectionRef.doc(docId);

  static bool _readShowDeleteAccount(DocumentSnapshot<Object?> snapshot) {
    if (!snapshot.exists) return false;
    final data = snapshot.data();
    if (data is! Map<String, dynamic>) return false;
    // Only an explicit `true` shows the option; a missing or non-bool value
    // keeps it hidden.
    return data[showDeleteAccountField] == true;
  }

  /// Whether the "Delete account" option should be shown.
  ///
  /// Returns `false` when the document, the field, or the network is
  /// unavailable, so the option stays hidden unless it is explicitly enabled.
  static Future<bool> isDeleteAccountEnabled() async {
    try {
      return _readShowDeleteAccount(await _docRef.get());
    } catch (e) {
      debugPrint('⚠️ Failed to read $showDeleteAccountField flag: $e');
      return false;
    }
  }

  /// Live updates of [isDeleteAccountEnabled], so toggling the flag in
  /// Firestore takes effect without restarting the app.
  static Stream<bool> watchDeleteAccountEnabled() {
    return _docRef.snapshots().map(_readShowDeleteAccount).handleError((
      Object e,
    ) {
      debugPrint('⚠️ Failed to watch $showDeleteAccountField flag: $e');
    });
  }
}
