import 'dart:async';
import 'dart:io';
import 'package:aboglumbo_bbk_panel/helpers/country_code_detector.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/pages/home/home.dart';
import 'package:aboglumbo_bbk_panel/pages/login/signup.dart';
import 'package:aboglumbo_bbk_panel/models/admin.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/services/app_settings_service.dart';
import 'package:aboglumbo_bbk_panel/services/otp_api.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static String? phoneNumber;

  /// Whether this device still holds a Firebase session for [uid] that the
  /// server accepts. A disabled or deleted account or a revoked session fails;
  /// an unreachable network does not, since the SDK re-checks on its next
  /// token refresh anyway.
  static Future<bool> hasValidSessionFor(String? uid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (uid == null ||
        uid.isEmpty ||
        user == null ||
        user.isAnonymous ||
        user.uid != uid) {
      return false;
    }
    try {
      await user.getIdToken(true);
      return true;
    } on FirebaseAuthException catch (e) {
      return e.code == 'network-request-failed';
    } catch (_) {
      return false;
    }
  }

  String _sanitizeOTP(String input) {
    // Remove spaces and convert Arabic digits to ASCII for OTP
    String result = input.replaceAll(RegExp(r'\s'), '');
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    const asciiDigits = '0123456789';
    for (int i = 0; i < arabicDigits.length; i++) {
      result = result.replaceAll(arabicDigits[i], asciiDigits[i]);
    }
    return result;
  }

  String? _verificationId;

  Future<void> sendOTP(
    BuildContext context, {
    required String phoneNumber,
    required Function(String verificationId, {int? resendToken}) onCodeSent,
    required Function(FirebaseAuthException e) onError,
    Function(PhoneAuthCredential credential)? onVerificationCompleted,
    int? forceResendingToken,
    OtpPurpose purpose = OtpPurpose.login,
    String? expectedUid,
  }) async {

    String sanitizedPhoneNumber = CountryCodeDetector.normalizeSaudiPhone(
      phoneNumber,
    );

    AuthServices.phoneNumber = sanitizedPhoneNumber;
    _verificationId = null;

    // Read before the first await, while the context is certainly valid.
    final locale = Localizations.localeOf(context).languageCode;
    final provider = await AppSettingsService.resolveOtpProvider();
    if (provider == OtpProvider.taqnyat) {
      await _sendTaqnyatOtp(
        phoneNumber: sanitizedPhoneNumber,
        purpose: purpose,
        locale: locale,
        expectedUid: expectedUid,
        onCodeSent: onCodeSent,
        onError: onError,
      );
      return;
    }

    try {
      if (Platform.isIOS) {
        await FirebaseAuth.instance.setSettings(
          appVerificationDisabledForTesting: false,
          userAccessGroup: null,
        );
      }

      _auth.verifyPhoneNumber(
        phoneNumber: sanitizedPhoneNumber,
        forceResendingToken: forceResendingToken,
        timeout: const Duration(seconds: 120),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Android only: the caller decides what to do with the credential
          // (sign in and route the user) instead of a silent sign-in here.
          if (onVerificationCompleted != null) {
            onVerificationCompleted(credential);
            return;
          }
          try {
            AuthServices.phoneNumber = sanitizedPhoneNumber;
            await _auth.signInWithCredential(credential);
          } catch (_) {
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId, resendToken: resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
        },
      );

    } catch (e) {
      if (e is FirebaseAuthException) {
        onError(e);
      } else {
        onError(FirebaseAuthException(code: 'unknown', message: e.toString()));
      }
      rethrow;
    }
  }

  Future<void> _sendTaqnyatOtp({
    required String phoneNumber,
    required OtpPurpose purpose,
    required String locale,
    required String? expectedUid,
    required Function(String verificationId, {int? resendToken}) onCodeSent,
    required Function(FirebaseAuthException e) onError,
  }) async {
    try {
      final verificationId = await OtpApi.requestOtp(
        phone: phoneNumber,
        purpose: purpose,
        locale: locale,
        expectedUid: expectedUid,
      );
      onCodeSent(verificationId);
    } on FirebaseAuthException catch (e) {
      onError(e);
    }
  }

  /// Moves the signed-in account to the number the code was sent to, keeping
  /// its UID, and returns the new number.
  Future<String> confirmPhoneChange({
    required String verificationId,
    required String otp,
    required String expectedUid,
  }) async {
    final newPhone = await OtpApi.verifyPhoneChange(
      verificationId: verificationId,
      code: _sanitizeOTP(otp),
      expectedUid: expectedUid,
    );
    AuthServices.phoneNumber = newPhone;
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      // The change is already saved; the session refreshes on its own later.
    }
    return newPhone;
  }

  Future<void> resendOTP({
    required String phoneNumber,
    required int? resendToken,
    required Function(String verificationId, {int? resendToken}) onCodeSent,
    required Function(FirebaseAuthException e) onError,
    Function(String verificationId)? onAutoRetrievalTimeout,
    String? currentVerificationId,
    OtpPurpose purpose = OtpPurpose.login,
    String locale = 'ar',
    String? expectedUid,
  }) async {

    String sanitizedPhoneNumber = CountryCodeDetector.normalizeSaudiPhone(
      phoneNumber,
    );

    if (OtpApi.isTaqnyatVerification(currentVerificationId)) {
      await _sendTaqnyatOtp(
        phoneNumber: sanitizedPhoneNumber,
        purpose: purpose,
        locale: locale,
        expectedUid: expectedUid,
        onCodeSent: onCodeSent,
        onError: onError,
      );
      return;
    }

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: sanitizedPhoneNumber,
        forceResendingToken: resendToken,
        timeout: const Duration(seconds: 120),
        verificationCompleted: (PhoneAuthCredential credential) {
          // Ignored, as after the first send: the OTP page verifies the code
          // the user types or shares. A silent sign-in here would use the
          // code up, and the user's own attempt would then fail as expired.
        },
        verificationFailed: (FirebaseAuthException e) {

          onError(e);
        },
        codeSent: (String verificationId, int? token) {

          _verificationId = verificationId;
          onCodeSent(verificationId, resendToken: token);
        },
        codeAutoRetrievalTimeout: (String verificationId) {

          _verificationId = verificationId;
          if (onAutoRetrievalTimeout != null) {
            onAutoRetrievalTimeout(verificationId);
          }
        },
      );
    } catch (e) {
      if (e is FirebaseAuthException) {
        onError(e);
      } else {
        onError(FirebaseAuthException(code: 'unknown', message: e.toString()));
      }
      rethrow;
    }
  }

  Future<UserCredential?> verifyOTP(
    BuildContext context,
    String otp, {
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
  }) async {
    try {
      String sanitizedOTP = _sanitizeOTP(otp);

      // Additional validation for iOS
      if (sanitizedOTP.isEmpty || sanitizedOTP.length != 6) {
        throw FirebaseAuthException(
          code: 'invalid-verification-code',
          message: 'Invalid OTP format. Please enter a 6-digit code.',
        );
      }

      if (OtpApi.isTaqnyatVerification(verificationId)) {
        final token = await OtpApi.verifyLogin(
          verificationId: verificationId,
          code: sanitizedOTP,
        );
        final userCredential = await _auth.signInWithCustomToken(token);
        AuthServices.phoneNumber = userCredential.user?.phoneNumber ?? '';
        return userCredential;
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: sanitizedOTP,
      );
      final tempUserCredential = await _auth.signInWithCredential(credential);
      final userPhoneNumber = tempUserCredential.user?.phoneNumber ?? '';

      AuthServices.phoneNumber = userPhoneNumber;

      return tempUserCredential;
    } catch (e) {
      if (e is FirebaseAuthException) {
        rethrow;
      } else {
        throw FirebaseAuthException(
          code: 'verification-failed',
          message: 'Failed to verify OTP: $e',
        );
      }
    }
  }

  Future<void> _handleAdminPromotion(
    String uid,
    AdminModel pendingAdmin,
  ) async {
    try {
      // Create admin document
      await AppFirestore.adminsCollectionRef
          .doc(uid)
          .set(pendingAdmin.copyWith(uid: uid).toJson());
      // Delete pending admin
      if (pendingAdmin.uid != null) {
        await AppFirestore.pendingAdminsCollectionRef
            .doc(pendingAdmin.uid)
            .delete();
      }
    } catch (_) {
    }
  }

  Future<void> checkUser({
    required UserCredential userCredential,
    required BuildContext context,
  }) async {
    try {
      final uid = userCredential.user?.uid;
      final phone = userCredential.user?.phoneNumber;

      if (uid == null) {
        return;
      }

      // 1. Check if user is in ACTIVE admins collection (by UID)
      final adminDoc = await AppFirestore.adminsCollectionRef.doc(uid).get();
      if (adminDoc.exists) {
        final adminData = adminDoc.data() as Map<String, dynamic>?;
        await LocalStore.putUID(uid);
        await LocalStore.putlogoutStatus(false);
        await LocalStore.storeAdminData(
          AdminModel.fromJson(adminData ?? {}, id: uid),
        );
        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
          (route) => false,
        );
        return;
      }

      // 2. Check if user is in PENDING admins collection by phone
      if (phone != null) {
        final pendingAdminQuery = await AppFirestore.pendingAdminsCollectionRef
            .where('phoneNumber', isEqualTo: phone)
            .limit(1)
            .get();

        if (pendingAdminQuery.docs.isNotEmpty) {
          final pendingAdmin = AdminModel.fromJson(
            pendingAdminQuery.docs.first.data() as Map<String, dynamic>,
            id: pendingAdminQuery.docs.first.id,
          );

          // Promote to active admin
          await _handleAdminPromotion(uid, pendingAdmin);

          await LocalStore.putUID(uid);
          await LocalStore.putlogoutStatus(false);
          await LocalStore.storeAdminData(pendingAdmin.copyWith(uid: uid));
          if (!context.mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Home()),
            (route) => false,
          );
          return;
        }
      }

      // 3. Check users collection for role "technician"
      final userDoc = await AppFirestore.usersCollectionRef.doc(uid).get();
      bool isValidTechnician = false;

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        final userRole =
            userData?['role']?.toString().toLowerCase() ?? 'technician';

        if (userRole == 'technician' &&
            userData != null &&
            userData['uid'] != null &&
            userData['uid'].toString().isNotEmpty) {
          isValidTechnician = true;
        }
      }

      if (isValidTechnician) {
        await LocalStore.putUID(uid);
        await LocalStore.putlogoutStatus(false);
        final userData =
            (await AppFirestore.usersCollectionRef.doc(uid).get()).data()
                as Map<String, dynamic>?;
        if (userData != null) {
          await LocalStore.storeUserData(UserModel.fromJson(userData));
        }

        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
          (route) => false,
        );
        return;
      }

      // 4. Check if phone number belongs to an admin in the admins collection (by phone)
      //    This handles admin users who log in for the first time on a new device
      if (phone != null) {
        final adminByPhoneQuery = await AppFirestore.adminsCollectionRef
            .where('phoneNumber', isEqualTo: phone)
            .limit(1)
            .get();

        if (adminByPhoneQuery.docs.isNotEmpty) {
          final existingAdminData =
              adminByPhoneQuery.docs.first.data() as Map<String, dynamic>?;

          // Create/update admin doc with current UID
          final adminModel = AdminModel.fromJson(
            existingAdminData ?? {},
            id: adminByPhoneQuery.docs.first.id,
          );
          // If the admin doc UID differs from current UID, update it
          if (adminModel.uid != uid) {
            await AppFirestore.adminsCollectionRef
                .doc(uid)
                .set(adminModel.copyWith(uid: uid).toJson());
            // Clean up old admin doc if it has a different ID
            if (adminByPhoneQuery.docs.first.id != uid) {
              await AppFirestore.adminsCollectionRef
                  .doc(adminByPhoneQuery.docs.first.id)
                  .delete();
            }
          }

          await LocalStore.putUID(uid);
          await LocalStore.putlogoutStatus(false);
          await LocalStore.storeAdminData(adminModel.copyWith(uid: uid));
          if (!context.mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Home()),
            (route) => false,
          );
          return;
        }
      }

      // 5. Check if phone exists in users collection as technician (prevents duplicate accounts)
      if (phone != null) {
        final techByPhoneQuery = await AppFirestore.usersCollectionRef
            .where('phone', isEqualTo: phone)
            .limit(1)
            .get();

        if (techByPhoneQuery.docs.isNotEmpty) {
          final oldDoc = techByPhoneQuery.docs.first;
          final oldData = oldDoc.data() as Map<String, dynamic>;
          final oldDocId = oldDoc.id;

          final userRole =
              oldData['role']?.toString().toLowerCase() ?? 'technician';
          if (userRole == 'technician') {
            // Migrate doc to new UID
            oldData['uid'] = uid;
            oldData['updatedAt'] = Timestamp.now();
            await AppFirestore.usersCollectionRef.doc(uid).set(oldData);

            // Delete old document
            if (oldDocId != uid) {
              await AppFirestore.usersCollectionRef.doc(oldDocId).delete();
            }

            await LocalStore.putUID(uid);
            await LocalStore.putlogoutStatus(false);
            await LocalStore.storeUserData(UserModel.fromJson(oldData));
            if (!context.mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Home()),
              (route) => false,
            );
            return;
          }
        }
      }

      // 6. User not found in any collection — redirect to signup
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Signup(uid: uid)),
        (route) => false,
      );
    } catch (e) {
      if (e is FirebaseAuthException) {
        rethrow;
      } else {
        throw FirebaseAuthException(
          code: 'check-user-failed',
          message: 'Failed to check user: $e',
        );
      }
    }
  }
}
