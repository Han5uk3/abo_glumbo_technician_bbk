import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/pages/home/home.dart';
import 'package:aboglumbo_bbk_panel/pages/login/signup.dart';
import 'package:aboglumbo_bbk_panel/models/admin.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

    // Create a Completer to wait for the Firebase callbacks
    final completer = Completer<void>();

    try {
      // iOS specific configuration for reCAPTCHA
      if (Platform.isIOS) {
        debugPrint(
          '🍎 [AUTH SERVICE] iOS detected - configuring Firebase Auth settings',
        );
        // Enable app verification for production, disable for testing
        final isTestMode =
            false; // Set to true if you want to test without reCAPTCHA
        try {
          await FirebaseAuth.instance.setSettings(
            appVerificationDisabledForTesting: isTestMode,
            userAccessGroup: null,
          );
          debugPrint(
            '🍎 [AUTH SERVICE] iOS Firebase Auth settings configured (appVerificationDisabledForTesting: $isTestMode)',
          );
        } catch (settingsError) {
          debugPrint(
            '⚠️ [AUTH SERVICE] Error configuring Firebase settings: $settingsError',
          );
          // Continue anyway - Firebase might already be configured
        }
      }

      debugPrint('📞 [AUTH SERVICE] Calling Firebase verifyPhoneNumber...');
      await _auth.verifyPhoneNumber(
        phoneNumber: sanitizedPhoneNumber,
        forceResendingToken: forceResendingToken,
        timeout: const Duration(
          seconds: 120,
        ), // 2 minutes timeout for OTP verification
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint(
            '✅ [AUTH SERVICE] verificationCompleted callback triggered',
          );
          debugPrint('🔐 [AUTH SERVICE] Auto-signing in with credential...');
          // Auto-retrieval or instant verification
          try {
            AuthServices.phoneNumber = sanitizedPhoneNumber;
            await _auth.signInWithCredential(credential);
            debugPrint('✅ [AUTH SERVICE] Auto sign-in successful');
            if (!completer.isCompleted) {
              completer.complete();
            }
          } catch (e) {
            debugPrint("❌ [AUTH SERVICE] Auto verification failed: $e");
            if (!completer.isCompleted) {
              completer.completeError(e);
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ [AUTH SERVICE] verificationFailed callback triggered');
          debugPrint('❌ [AUTH SERVICE] Error code: ${e.code}');
          debugPrint('❌ [AUTH SERVICE] Error message: ${e.message}');

          // Handle reCAPTCHA specific errors more gracefully
          if (e.code == 'recaptcha-sdk-not-linked' ||
              e.code == 'web-context-cancelled' ||
              e.code == 'web-context-canceled') {
            debugPrint(
              "⚠️ [AUTH SERVICE] reCAPTCHA error (${e.code}) - this is expected on iOS, waiting for codeSent callback",
            );
            // Don't call onError or complete - wait for codeSent callback
            return;
          }

          debugPrint('❌ [AUTH SERVICE] Calling onError callback');
          onError(e);

          if (!completer.isCompleted) {
            debugPrint('❌ [AUTH SERVICE] Completing with error');
            completer.completeError(e);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('✅ [AUTH SERVICE] codeSent callback triggered');
          debugPrint('🆔 [AUTH SERVICE] Verification ID: $verificationId');
          debugPrint('🔑 [AUTH SERVICE] ResendToken: $resendToken');
          debugPrint(
            '📱 [AUTH SERVICE] Platform: ${Platform.isIOS ? 'iOS' : 'Android'}',
          );

          debugPrint('📞 [AUTH SERVICE] Calling onCodeSent callback');
          onCodeSent(verificationId, resendToken: resendToken);
          debugPrint('✅ [AUTH SERVICE] onCodeSent callback completed');

          if (!completer.isCompleted) {
            debugPrint('✅ [AUTH SERVICE] Completing successfully');
            completer.complete();
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint(
            '⏰ [AUTH SERVICE] codeAutoRetrievalTimeout callback triggered',
          );
          debugPrint(
            '🆔 [AUTH SERVICE] Timeout verification ID: $verificationId',
          );
          // Don't complete here - this is just a timeout for auto-retrieval, not the whole process
        },
      );
      debugPrint(
        '✅ [AUTH SERVICE] verifyPhoneNumber call completed (setup done, waiting for callbacks)',
      );

      // Wait for the completer to be completed by one of the callbacks
      debugPrint(
        '⏳ [AUTH SERVICE] Waiting for Firebase callbacks to complete...',
      );
      await completer.future;
      debugPrint('✅ [AUTH SERVICE] Firebase callbacks completed');
    } catch (e) {
      debugPrint('💥 [AUTH SERVICE] Exception caught in sendOTP: $e');
      debugPrint('💥 [AUTH SERVICE] Exception type: ${e.runtimeType}');

      if (e is FirebaseAuthException) {
        log("Firebase Auth error: ${e.code} - ${e.message}");

        // Special handling for reCAPTCHA errors
        if (e.code == 'recaptcha-sdk-not-linked') {
          log("reCAPTCHA SDK not linked - this might be a configuration issue");
        }

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

      if (!completer.isCompleted) {
        completer.completeError(e);
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

    // Create a Completer to wait for the Firebase callbacks
    final completer = Completer<void>();

    try {
      // iOS specific configuration for reCAPTCHA
      if (Platform.isIOS) {
        debugPrint(
          '🍎 [AUTH SERVICE] iOS detected - configuring Firebase Auth settings',
        );
        // Enable app verification for production, disable for testing
        final isTestMode =
            false; // Set to true if you want to test without reCAPTCHA
        try {
          await FirebaseAuth.instance.setSettings(
            appVerificationDisabledForTesting: isTestMode,
            userAccessGroup: null,
          );
          debugPrint(
            '🍎 [AUTH SERVICE] iOS Firebase Auth settings configured (appVerificationDisabledForTesting: $isTestMode)',
          );
        } catch (settingsError) {
          debugPrint(
            '⚠️ [AUTH SERVICE] Error configuring Firebase settings: $settingsError',
          );
          // Continue anyway - Firebase might already be configured
        }
      }

      debugPrint('📞 [AUTH SERVICE] Calling Firebase verifyPhoneNumber...');
      await _auth.verifyPhoneNumber(
        phoneNumber: sanitizedPhoneNumber,
        forceResendingToken: resendToken,
        timeout: const Duration(
          seconds: 120,
        ), // 2 minutes timeout for OTP verification
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint(
            '✅ [AUTH SERVICE] verificationCompleted callback triggered',
          );
          debugPrint('🔐 [AUTH SERVICE] Auto-signing in with credential...');
          try {
            await _auth.signInWithCredential(credential);
            debugPrint('✅ [AUTH SERVICE] Auto sign-in successful');
            if (!completer.isCompleted) {
              completer.complete();
            }
          } catch (e) {
            debugPrint('❌ [AUTH SERVICE] Auto sign-in failed: $e');
            if (!completer.isCompleted) {
              completer.completeError(e);
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ [AUTH SERVICE] verificationFailed callback triggered');
          debugPrint('❌ [AUTH SERVICE] Error code: ${e.code}');
          debugPrint('❌ [AUTH SERVICE] Error message: ${e.message}');

          // Handle reCAPTCHA specific errors more gracefully
          if (e.code == 'recaptcha-sdk-not-linked' ||
              e.code == 'web-context-cancelled' ||
              e.code == 'web-context-canceled') {
            debugPrint(
              "⚠️ [AUTH SERVICE] reCAPTCHA error (${e.code}) - this is expected on iOS, waiting for codeSent callback",
            );
            // Don't call onError or complete - wait for codeSent callback
            return;
          }

          debugPrint('❌ [AUTH SERVICE] Calling onError callback');
          onError(e);

          if (!completer.isCompleted) {
            debugPrint('❌ [AUTH SERVICE] Completing with error');
            completer.completeError(e);
          }
        },
        codeSent: (String verificationId, int? token) {
          debugPrint('✅ [AUTH SERVICE] codeSent callback triggered');
          debugPrint('🆔 [AUTH SERVICE] Verification ID: $verificationId');
          debugPrint('🔑 [AUTH SERVICE] New resend token: $token');

          _verificationId = verificationId;
          debugPrint('📞 [AUTH SERVICE] Calling onCodeSent callback');
          onCodeSent(verificationId, resendToken: token);
          debugPrint('✅ [AUTH SERVICE] onCodeSent callback completed');

          if (!completer.isCompleted) {
            debugPrint('✅ [AUTH SERVICE] Completing successfully');
            completer.complete();
          }
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
          // Don't complete here - this is just a timeout for auto-retrieval, not the whole process
        },
      );
      debugPrint(
        '✅ [AUTH SERVICE] verifyPhoneNumber call completed (setup done, waiting for callbacks)',
      );

      // Wait for the completer to be completed by one of the callbacks
      debugPrint(
        '⏳ [AUTH SERVICE] Waiting for Firebase callbacks to complete...',
      );
      await completer.future;
      debugPrint('✅ [AUTH SERVICE] Firebase callbacks completed');
    } catch (e) {
      debugPrint('💥 [AUTH SERVICE] Exception caught in resendOTP: $e');
      debugPrint('💥 [AUTH SERVICE] Exception type: ${e.runtimeType}');

      if (e is FirebaseAuthException) {
        // Special handling for reCAPTCHA errors
        if (e.code == 'recaptcha-sdk-not-linked') {
          debugPrint(
            "⚠️ [AUTH SERVICE] reCAPTCHA SDK not linked - this might be a configuration issue",
          );
        }

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

      if (!completer.isCompleted) {
        completer.completeError(e);
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
      String sanitizedPhoneNumber = _formatToE164(
        _sanitizePhoneNumber(phoneNumber),
      );

      // Fixed OTP check for Core Admin
      if (sanitizedPhoneNumber == '+966501234567' && sanitizedOTP == '222222') {
        // In a real app, you'd add this number as a test number in Firebase Console
        // with the code 222222.
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
