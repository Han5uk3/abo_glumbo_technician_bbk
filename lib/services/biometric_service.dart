import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> authenticate(BuildContext context) async {
    try {
      return await _auth.authenticate(
        localizedReason:
            AppLocalizations.of(context)?.enableBiometricAuthentication ??
            'Please authenticate to continue',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  // ✅ FIXED: Use current UID (when logged in) or last valid UID (after logout)
  static Future<void> setBiometricEnabled(bool enabled) async {
    final uid = LocalStore.getUID() ?? LocalStore.getLastValidUID() ?? '';
    await LocalStore.setBiometricAuthEnabled(enabled, uid);
  }

  // ✅ FIXED: Check last valid UID for biometric status
  static Future<bool> isBiometricEnabled() async {
    final uid = LocalStore.getUID() ?? LocalStore.getLastValidUID() ?? '';
    return LocalStore.getBiometricAuthEnabled(uid);
  }
}
