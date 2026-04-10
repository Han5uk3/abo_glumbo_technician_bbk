import 'dart:async';
import 'dart:io';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/pages/home/home.dart';
import 'package:aboglumbo_bbk_panel/pages/login/signup.dart';
import 'package:aboglumbo_bbk_panel/models/admin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static String? phoneNumber;

  String _sanitizePhoneNumber(String input) {
    if (input.startsWith("+966")) {
      String countryCode = "+966";
      String numberPart = input.substring(4);
      String sanitizedNumberPart = _sanitizeNumberPart(numberPart);
      String result = countryCode + sanitizedNumberPart;
      return result;
    }
    String sanitizedNumberPart = _sanitizeNumberPart(input);
    return sanitizedNumberPart;
  }

  String _sanitizeNumberPart(String input) {
    String result = input.replaceAll(RegExp(r'\s'), '');
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    const asciiDigits = '0123456789';
    for (int i = 0; i < arabicDigits.length; i++) {
      result = result.replaceAll(arabicDigits[i], asciiDigits[i]);
    }
    return result;
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

  String _formatToE164(String phoneNumber) {
    String sanitized = phoneNumber;
    if (sanitized.startsWith('+966')) {
      return sanitized;
    }
    while (sanitized.startsWith('0')) {
      sanitized = sanitized.substring(1);
    }
    String e164Number = '+966$sanitized';
    return e164Number;
  }

  String? _verificationId;

  Future<void> sendOTP(
    BuildContext context, {
    required String phoneNumber,
    required Function(String verificationId, {int? resendToken}) onCodeSent,
    required Function(FirebaseAuthException e) onError,
    int? forceResendingToken,
  }) async {
    debugPrint('🟢 [AUTH SERVICE] sendOTP method called');
    debugPrint('📱 [AUTH SERVICE] Phone number: $phoneNumber');

    String sanitizedPhoneNumber = _formatToE164(
      _sanitizePhoneNumber(phoneNumber),
    );
    debugPrint('🔢 [AUTH SERVICE] Sanitized number: $sanitizedPhoneNumber');
    debugPrint(
      '📱 [AUTH SERVICE] Platform: ${Platform.isIOS ? "iOS" : "Android"}',
    );

    AuthServices.phoneNumber = sanitizedPhoneNumber;
    _verificationId = null;

    try {
      if (Platform.isIOS) {
        if (kDebugMode) {
          debugPrint(
            '🍎 [AUTH SERVICE] Debug mode: appVerificationDisabledForTesting set to true',
          );
          await FirebaseAuth.instance.setSettings(
            appVerificationDisabledForTesting: true,
            userAccessGroup: null,
          );
        } else {
          debugPrint(
            '🍎 [AUTH SERVICE] Production mode: appVerificationDisabledForTesting set to false',
          );
          await FirebaseAuth.instance.setSettings(
            appVerificationDisabledForTesting: false,
            // In production, we don't set userAccessGroup to null unless we know it should be.
            // Leaving it as default is safer.
          );
        }
      }

      debugPrint(
        '📞 [AUTH SERVICE] Calling Firebase verifyPhoneNumber (no-await version)...',
      );

      _auth.verifyPhoneNumber(
        phoneNumber: sanitizedPhoneNumber,
        forceResendingToken: forceResendingToken,
        timeout: const Duration(seconds: 120),
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('✅ [AUTH SERVICE] verificationCompleted triggered');
          try {
            AuthServices.phoneNumber = sanitizedPhoneNumber;
            await _auth.signInWithCredential(credential);
            debugPrint('✅ [AUTH SERVICE] Auto sign-in successful');
          } catch (e) {
            debugPrint(
              "❌ [AUTH SERVICE] Auto verification sign-in failed: $e",
            );
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ [AUTH SERVICE] verificationFailed triggered');
          debugPrint('❌ [AUTH SERVICE] Code: ${e.code}');
          debugPrint('❌ [AUTH SERVICE] Message: ${e.message}');
          onError(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('✅ [AUTH SERVICE] codeSent triggered');
          debugPrint('🆔 [AUTH SERVICE] ID: $verificationId');
          onCodeSent(verificationId, resendToken: resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('⏰ [AUTH SERVICE] codeAutoRetrievalTimeout triggered');
        },
      );

      debugPrint('✅ [AUTH SERVICE] verifyPhoneNumber call initiated');
    } catch (e) {
      debugPrint('💥 [AUTH SERVICE] Exception in sendOTP: $e');
      if (e is FirebaseAuthException) {
        onError(e);
      } else {
        onError(FirebaseAuthException(code: 'unknown', message: e.toString()));
      }
      rethrow;
    }
    debugPrint('🏁 [AUTH SERVICE] sendOTP method complete');
  }

  Future<void> resendOTP({
    required String phoneNumber,
    required int? resendToken,
    required Function(String verificationId, {int? resendToken}) onCodeSent,
    required Function(FirebaseAuthException e) onError,
    Function(String verificationId)? onAutoRetrievalTimeout,
  }) async {
    debugPrint('🔵 [AUTH SERVICE] resendOTP method called');
    debugPrint('📱 [AUTH SERVICE] Phone number: $phoneNumber');
    debugPrint('🔑 [AUTH SERVICE] Resend token: $resendToken');

    String sanitizedPhoneNumber = _formatToE164(
      _sanitizePhoneNumber(phoneNumber),
    );
    debugPrint(
      '🔢 [AUTH SERVICE] Sanitized phone number: $sanitizedPhoneNumber',
    );

    try {
      debugPrint('📞 [AUTH SERVICE] Calling Firebase verifyPhoneNumber...');
      await _auth.verifyPhoneNumber(
        phoneNumber: sanitizedPhoneNumber,
        forceResendingToken: resendToken,
        timeout: const Duration(seconds: 120),
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint(
            '✅ [AUTH SERVICE] verificationCompleted callback triggered',
          );
          debugPrint('🔐 [AUTH SERVICE] Auto-signing in with credential...');
          try {
            debugPrint("Auto-verification completed during resend OTP");
            await _auth.signInWithCredential(credential);
            debugPrint('✅ [AUTH SERVICE] Auto sign-in successful');
          } catch (e) {
            debugPrint(
              "❌ [AUTH SERVICE] Auto verification failed during resend: $e",
            );
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ [AUTH SERVICE] verificationFailed callback triggered');
          debugPrint('❌ [AUTH SERVICE] Error code: ${e.code}');
          debugPrint('❌ [AUTH SERVICE] Error message: ${e.message}');

          debugPrint('❌ [AUTH SERVICE] Calling onError callback');
          onError(e);
        },
        codeSent: (String verificationId, int? token) {
          debugPrint('✅ [AUTH SERVICE] codeSent callback triggered');
          debugPrint('🆔 [AUTH SERVICE] Verification ID: $verificationId');
          debugPrint('🔑 [AUTH SERVICE] New resend token: $token');

          _verificationId = verificationId;
          debugPrint('📞 [AUTH SERVICE] Calling onCodeSent callback');
          onCodeSent(verificationId, resendToken: token);
          debugPrint('✅ [AUTH SERVICE] onCodeSent callback completed');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint(
            '⏰ [AUTH SERVICE] codeAutoRetrievalTimeout callback triggered',
          );
          debugPrint(
            '🆔 [AUTH SERVICE] Timeout verification ID: $verificationId',
          );

          _verificationId = verificationId;
          if (onAutoRetrievalTimeout != null) {
            debugPrint(
              '📞 [AUTH SERVICE] Calling onAutoRetrievalTimeout callback',
            );
            onAutoRetrievalTimeout(verificationId);
          }
        },
      );
      debugPrint(
        '✅ [AUTH SERVICE] verifyPhoneNumber call completed (setup done, waiting for callbacks)',
      );
    } catch (e) {
      debugPrint('💥 [AUTH SERVICE] Exception caught in resendOTP: $e');
      if (e is FirebaseAuthException) {
        debugPrint(
          '❌ [AUTH SERVICE] Calling onError callback from catch block',
        );
        onError(e);
      } else {
        debugPrint(
          '❌ [AUTH SERVICE] Unknown error - wrapping in FirebaseAuthException',
        );
        onError(FirebaseAuthException(code: 'unknown', message: e.toString()));
      }
      rethrow;
    }
    debugPrint('🏁 [AUTH SERVICE] resendOTP method complete');
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

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: sanitizedOTP,
      );
      final tempUserCredential = await _auth.signInWithCredential(credential);
      final userPhoneNumber = tempUserCredential.user?.phoneNumber ?? '';

      AuthServices.phoneNumber = userPhoneNumber;

      return tempUserCredential;
    } catch (e) {
      debugPrint("Error verifying OTP: $e");
      if (e is FirebaseAuthException) {
        // Enhanced error handling for iOS-specific issues
        switch (e.code) {
          case 'invalid-verification-code':
            debugPrint("iOS: Invalid verification code provided");
            break;
          case 'session-expired':
            debugPrint("iOS: OTP session expired");
            break;
          case 'too-many-requests':
            debugPrint("iOS: Too many requests - temporarily blocked");
            break;
          case 'network-request-failed':
            debugPrint("iOS: Network request failed");
            break;
          default:
            debugPrint("iOS: Unknown error - ${e.code}: ${e.message}");
        }
        rethrow;
      } else {
        throw FirebaseAuthException(
          code: 'verification-failed',
          message: 'Failed to verify OTP: $e',
        );
      }
    }
  }

  Future<void> _handleAdminPromotion(String uid, AdminModel pendingAdmin) async {
    try {
      // Create admin document
      await AppFirestore.adminsCollectionRef.doc(uid).set(
        pendingAdmin.copyWith(uid: uid).toJson(),
      );
      // Delete pending admin
      if (pendingAdmin.uid != null) {
        await AppFirestore.pendingAdminsCollectionRef.doc(pendingAdmin.uid).delete();
      }
    } catch (e) {
      debugPrint("Error promoting admin: $e");
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
        debugPrint("Error: User UID is null");
        return;
      }

      // 1. Check if user is in ACTIVE admins collection
      final adminDoc = await AppFirestore.adminsCollectionRef.doc(uid).get();
      if (adminDoc.exists) {
        LocalStore.putUID(uid);
        LocalStore.putlogoutStatus(false);
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

          LocalStore.putUID(uid);
          LocalStore.putlogoutStatus(false);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Home()),
            (route) => false,
          );
          return;
        }
      }

      // 3. Fallback to existing Worker/Technician check
      final userDoc = await AppFirestore.usersCollectionRef.doc(uid).get();
      bool isValidUser = false;

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        if (userData != null &&
            userData['uid'] != null &&
            userData['uid'].toString().isNotEmpty) {
          isValidUser = true;
        }
      }

      if (isValidUser) {
        LocalStore.putUID(uid);
        LocalStore.putlogoutStatus(false);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
          (route) => false,
        );
      } else {
        // Core admin check (if not in admins or techs yet)
        if (phone == '+966501234567') {
          // Create core admin
          final coreAdmin = AdminModel(
            uid: uid,
            name: 'Core Admin',
            email: 'core@admin.com',
            phoneNumber: '+966501234567',
            accessLevel: 2, // Full Admin
            isCoreAdmin: true,
          );
          await AppFirestore.adminsCollectionRef.doc(uid).set(coreAdmin.toJson());

          LocalStore.putUID(uid);
          LocalStore.putlogoutStatus(false);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Home()),
            (route) => false,
          );
          return;
        }

        debugPrint("Redirecting to Signup (User not found or invalid): $uid");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Signup(uid: uid)),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Error in checkUser: $e");
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
