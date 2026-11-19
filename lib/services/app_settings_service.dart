import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Which service delivers login codes.
enum OtpProvider { taqnyat, firebase }

/// Reads remote feature flags from `app_settings/technician_app_v1`.
///
/// Flags are controlled server-side so options can be toggled without a new
/// app release.
class AppSettingsService {
  /// Settings document for this app.
  static const String docId = 'technician_app_v1';

  /// Flag deciding whether the "Delete account" option is offered.
  static const String showDeleteAccountField = 'showDeleteAccount';

  /// Set to `firebase` to fall back to Firebase SMS, for example during a
  /// Taqnyat outage. Any other value, or none, uses Taqnyat.
  static const String otpProviderField = 'otpProvider';

  static const Duration _otpProviderTimeout = Duration(milliseconds: 2500);

  static DocumentReference<Object?> get _docRef =>
      AppFirestore.appSettingsCollectionRef.doc(docId);

  static OtpProvider _parseOtpProvider(Object? value) =>
      value == OtpProvider.firebase.name
      ? OtpProvider.firebase
      : OtpProvider.taqnyat;

  /// The provider to use for the login the user just started.
  ///
  /// The wait is bounded so a slow network cannot hold up login. If the flag
  /// cannot be read, the last value seen on this device applies.
  static Future<OtpProvider> resolveOtpProvider() async {
    try {
      final snapshot = await _docRef
          .get(const GetOptions(source: Source.server))
          .timeout(_otpProviderTimeout);
      final data = snapshot.data();
      final provider = _parseOtpProvider(
        data is Map<String, dynamic> ? data[otpProviderField] : null,
      );
      await LocalStore.putOtpProvider(provider.name);
      return provider;
    } catch (e) {
      return _parseOtpProvider(LocalStore.getOtpProvider());
    }
  }

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
      return false;
    }
  }

  /// Live updates of [isDeleteAccountEnabled], so toggling the flag in
  /// Firestore takes effect without restarting the app.
  static Stream<bool> watchDeleteAccountEnabled() {
    return _docRef.snapshots().map(_readShowDeleteAccount).handleError((
      Object e,
    ) {
    });
  }
}
