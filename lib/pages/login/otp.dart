import 'dart:async';

import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/pages/login/login.dart';
import 'package:aboglumbo_bbk_panel/services/auth_services.dart';
import 'package:aboglumbo_bbk_panel/services/sms_autofill_service.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class OtpPage extends StatefulWidget {
  final String? phoneNumber;
  final String? verificationId;
  final int? resendToken;
  final bool? isFromProfile;
  const OtpPage({
    super.key,
    this.phoneNumber,
    this.verificationId,
    this.resendToken,
    this.isFromProfile,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  bool isLoading = false;
  bool isResendingOtp = false;
  bool _isMigratingCustomerData = false;
  bool _isSmsAutofillListening = false;
  int resendSeconds = 60;
  Timer? _timer;
  Timer? _smsListeningTimer;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String? _verificationId;
  int? _resendToken;
  bool _isDialogShowing = false;
  final SmsAutofillService _smsAutofillService = SmsAutofillService();

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _resendToken = widget.resendToken;
    startTimer();
    _startSmsAutofillListener();
  }

  // Get the complete OTP from all controllers
  String get _fullOtp => _otpController.text;

  int get _remainingTime => resendSeconds;
  String get _formattedTime {
    int minutes = resendSeconds ~/ 60;
    int seconds = resendSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void startTimer() {
    _timer?.cancel();
    resendSeconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendSeconds > 0) {
        if (mounted) {
          setState(() {
            resendSeconds--;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  void resendOTP() async {
    if (resendSeconds > 0) {
      debugPrint(
        '🚫 [RESEND OTP] Cannot resend - timer still active: $resendSeconds seconds remaining',
      );
      return;
    }
    if (isResendingOtp) return;

    debugPrint('🔄 [RESEND OTP] Starting resend OTP process');
    debugPrint('📱 [RESEND OTP] Phone number: ${widget.phoneNumber}');
    debugPrint('🔑 [RESEND OTP] Current resend token: $_resendToken');
    debugPrint('🆔 [RESEND OTP] Current verification ID: $_verificationId');

    setState(() {
      isResendingOtp = true;
    });
    debugPrint('⏳ [RESEND OTP] Loading state set to TRUE');

    try {
      debugPrint('📞 [RESEND OTP] Calling AuthServices().resendOTP...');
      await AuthServices().resendOTP(
        phoneNumber: widget.phoneNumber ?? '',
        resendToken: _resendToken,
        onCodeSent: (verificationId, {int? resendToken}) {
          debugPrint('✅ [RESEND OTP] onCodeSent callback triggered!');
          debugPrint('🆔 [RESEND OTP] New verification ID: $verificationId');
          debugPrint('🔑 [RESEND OTP] New resend token: $resendToken');

          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _resendToken = resendToken;

              // Clear all OTP fields when resending
              _otpController.clear();
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.otpSent),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );

            startTimer();
            debugPrint('⏱️ [RESEND OTP] Timer restarted');
          }
        },
        onAutoRetrievalTimeout: (verificationId) {
          debugPrint(
            '⏰ [RESEND OTP] onAutoRetrievalTimeout callback triggered',
          );
          debugPrint(
            '🆔 [RESEND OTP] Timeout verification ID: $verificationId',
          );

          if (mounted) {
            setState(() {
              _verificationId = verificationId;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)?.smsRetrievalTimedOut ??
                      'SMS Retrieval Timed Out',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
        onError: (error) {
          debugPrint('❌ [RESEND OTP] onError callback triggered');
          debugPrint('❌ [RESEND OTP] Error code: ${error.code}');
          debugPrint('❌ [RESEND OTP] Error message: ${error.message}');

          if (mounted) {
            String errorMessage;
            switch (error.code) {
              case 'too-many-requests':
                errorMessage =
                    AppLocalizations.of(context)?.tooManyRequests ??
                    'Too many attempts. Please wait and try again.';
                break;
              case 'quota-exceeded':
                errorMessage =
                    AppLocalizations.of(context)?.quotaExceeded ??
                    'SMS quota exceeded. Try again later.';
                break;
              case 'network-request-failed':
                errorMessage =
                    AppLocalizations.of(context)?.networkError ??
                    'Network error. Please check your connection.';
                break;
              case 'session-expired':
                errorMessage =
                    AppLocalizations.of(context)?.otpExpired ??
                    'OTP expired. Please request a new OTP.';
                break;
              case 'internal-error':
                errorMessage =
                    AppLocalizations.of(context)?.internalError ??
                    'An internal error occurred. Please try again later.';
                break;
              default:
                errorMessage = error.message ?? 'Failed to resend OTP';
            }

            debugPrint('📢 [RESEND OTP] Showing error message: $errorMessage');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage.isEmpty ? 'Error' : errorMessage),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
      );
      debugPrint(
        '✅ [RESEND OTP] AuthServices().resendOTP completed (await finished)',
      );
    } catch (e) {
      debugPrint('💥 [RESEND OTP] Exception caught in try-catch: $e');
      debugPrint('💥 [RESEND OTP] Exception type: ${e.runtimeType}');

      // Catch any unexpected errors that weren't handled by onError callback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.failedResendOtp ??
                  'Failed to resend OTP. Please try again.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      debugPrint('🏁 [RESEND OTP] Finally block executing');
      // Always reset the loading state, regardless of success or failure
      if (mounted) {
        setState(() {
          isResendingOtp = false;
        });
        debugPrint('⏳ [RESEND OTP] Loading state set to FALSE');
      }
      debugPrint('🏁 [RESEND OTP] Resend OTP process complete');
    }
  }

  Future<void> migrateUserData(
    String oldUid,
    String newUid,
    String newPhone,
  ) async {
    try {
      if (mounted) {
        setState(() => _isMigratingCustomerData = true);
        _showMigrationDialog();
      }

      // Migrate from users collection
      final oldUserDoc = await AppFirestore.usersCollectionRef
          .doc(oldUid)
          .get();
      if (oldUserDoc.exists) {
        final oldData = oldUserDoc.data() as Map<String, dynamic>;
        final newData = <String, dynamic>{
          ...oldData,
          'uid': newUid,
          'phone': newPhone,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        await AppFirestore.usersCollectionRef.doc(newUid).set(newData);
        await AppFirestore.usersCollectionRef.doc(oldUid).delete();
      }

      // Migrate from admins collection
      final oldAdminDoc = await AppFirestore.adminsCollectionRef
          .doc(oldUid)
          .get();
      if (oldAdminDoc.exists) {
        final oldData = oldAdminDoc.data() as Map<String, dynamic>;
        final newData = <String, dynamic>{
          ...oldData,
          'uid': newUid,
          'phone': newPhone,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        await AppFirestore.adminsCollectionRef.doc(newUid).set(newData);
        await AppFirestore.adminsCollectionRef.doc(oldUid).delete();
      }

      // Update bookings where this user is the agent
      final bookingsQuery = await AppFirestore.bookingsCollectionRef
          .where('agent.uid', isEqualTo: oldUid)
          .get();
      if (bookingsQuery.docs.isNotEmpty) {
        for (final bookingDoc in bookingsQuery.docs) {
          final Map<String, dynamic> updatedAgent = Map<String, dynamic>.from(
            bookingDoc['agent'] ?? {},
          );
          updatedAgent['uid'] = newUid;
          updatedAgent['phone'] = newPhone;
          updatedAgent['updatedAt'] = FieldValue.serverTimestamp();

          await AppFirestore.bookingsCollectionRef.doc(bookingDoc.id).update({
            'agent': updatedAgent,
          });
        }
      }

      final notificationQuery = await AppFirestore.notificationsCollectionRef
          .where('userId', isEqualTo: oldUid)
          .get();
      if (notificationQuery.docs.isNotEmpty) {
        for (final notificationDoc in notificationQuery.docs) {
          await AppFirestore.notificationsCollectionRef
              .doc(notificationDoc.id)
              .update({'userId': newUid});
        }
      }

      if (mounted) {
        setState(() => _isMigratingCustomerData = false);
        _closeMigrationDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isMigratingCustomerData = false);
        _closeMigrationDialog();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)?.unexpectedErrorOccurred}: $e',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void verifyOtp() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    final otp = _fullOtp;

    // Validate OTP length
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.enterOtp),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    final verificationId = _verificationId ?? widget.verificationId;

    if (verificationId == null) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.verificationIdNotFound ??
                'Verification ID not found. Please try again.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final UserCredential? userCredential = await AuthServices().verifyOTP(
        context,
        otp,
        verificationId: verificationId,
        smsCode: otp,
        phoneNumber: widget.phoneNumber ?? '',
      );
      if (userCredential == null) return;
      if (widget.isFromProfile == true) {
        final String oldUid = LocalStore.getUID() ?? '';
        final String newUid = userCredential.user?.uid ?? '';
        if (oldUid.isNotEmpty && newUid.isNotEmpty && oldUid != newUid) {
          await migrateUserData(
            oldUid,
            newUid,
            userCredential.user?.phoneNumber ?? '',
          );
        }
        LocalStore.clearUID();
        LocalStore.putlogoutStatus(true);
        await FirebaseAuth.instance.signOut();
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() => isLoading = false);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      } else {
        await AuthServices().checkUser(
          userCredential: userCredential,
          context: context,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });

        String errorMessage = AppLocalizations.of(
          context,
        )!.invalidOtpCode; // Localized message for invalid OTP
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'invalid-verification-code':
              errorMessage = AppLocalizations.of(
                context,
              )!.invalidOtpCode; // Localized message for invalid OTP
              break;
            case 'session-expired':
              errorMessage = AppLocalizations.of(
                context,
              )!.otpExpired; // Localized message for expired OTP
              break;
            case 'too-many-requests':
              errorMessage =
                  AppLocalizations.of(context)?.tooManyRequests ??
                  'Too many attempts. Please wait and try again.';
              break;
            case 'network-request-failed':
              errorMessage =
                  AppLocalizations.of(context)?.networkError ??
                  'Network error. Please check your connection.';
              break;
            case 'quota-exceeded':
              errorMessage =
                  AppLocalizations.of(context)?.quotaExceeded ??
                  'SMS quota exceeded. Try again later.';
              break;
            case 'internal-error':
              errorMessage =
                  AppLocalizations.of(context)?.internalError ??
                  'An internal error occurred. Please try again later.';
              break;
            default:
              errorMessage =
                  e.message ?? 'Verification failed. Please try again.';
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Clear all OTP fields on error
        _otpController.clear();
        // Focus on first field
        _focusNode.requestFocus();
      }
    }
  }

  /// Start listening for incoming SMS
  void _startSmsAutofillListener() {
    debugPrint('🎯 [PANEL OTP] Starting SMS autofill listener...');

    if (!mounted) return;

    setState(() {
      _isSmsAutofillListening = true;
    });

    // Set a timeout for SMS listening (30 seconds)
    _smsListeningTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        setState(() {
          _isSmsAutofillListening = false;
        });
        _smsAutofillService.cancelListening();
        debugPrint('⏰ [PANEL OTP] SMS listening timeout reached');
      }
    });

    _listenForSmsCode();
  }

  /// Listen for SMS code and auto-fill the OTP field
  void _listenForSmsCode() async {
    try {
      debugPrint('👂 [PANEL OTP] Listening for SMS code...');

      final smsCode = await _smsAutofillService.listenForSms(
        timeout: const Duration(seconds: 30),
      );

      if (smsCode != null && smsCode.isNotEmpty && mounted) {
        _otpController.text = smsCode;

        // Clear the form to reset validation
        _formKey.currentState?.reset();

        setState(() {
          _isSmsAutofillListening = false;
        });

        // Cancel the listening timer
        _smsListeningTimer?.cancel();

        // Automatically verify the OTP after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          debugPrint('🔐 [PANEL OTP] Auto-verifying OTP from SMS...');
          verifyOtp();
        }
      }
    } catch (e) {
      debugPrint('❌ [PANEL OTP] Error listening for SMS: $e');
      if (mounted) {
        setState(() {
          _isSmsAutofillListening = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _smsListeningTimer?.cancel();
    _smsAutofillService.cancelListening();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locn = AppLocalizations.of(context);
    if (locn == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.bgBlueTint,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.bgWhite,
        leading: IconButton(
          iconSize: 18,
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        ),
        title: Text(
          locn.enterOtp,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.normal,
            color: Colors.black,
          ),
        ),
      ),
      body: AbsorbPointer(
        absorbing: _isMigratingCustomerData,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RichText(
                            text: TextSpan(
                              text: locn.otpHasbeensentto,
                              style: TextStyle(
                                color: Colors.black45,
                                fontSize: 14,
                              ),
                              children: [
                                WidgetSpan(
                                  child: Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Text(
                                      " ${widget.phoneNumber ?? ''} ",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 6 OTP Boxes
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Pinput(
                                length: 6,
                                controller: _otpController,
                                focusNode: _focusNode,
                                defaultPinTheme: PinTheme(
                                  width: 45,
                                  height: 60,
                                  textStyle: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                focusedPinTheme: PinTheme(
                                  width: 45,
                                  height: 60,
                                  textStyle: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.secondary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                onCompleted: (pin) {
                                  FocusScope.of(context).unfocus();
                                  verifyOtp();
                                },
                              ),
                            ),
                            if (_isSmsAutofillListening)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: AppColors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      locn.listeningForSms,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _remainingTime > 0
                                ? '${locn.resend} ($_formattedTime)'
                                : locn.didNotReceiveOTP,
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                          if (_remainingTime <= 0) ...[
                            const SizedBox(width: 4),
                            TextButton(
                              onPressed: isResendingOtp ? null : resendOTP,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: isResendingOtp
                                  ? Loader(color: AppColors.green, size: 16)
                                  : Text(
                                      locn.resend,
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 24),
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : verifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            disabledBackgroundColor: AppColors.primary
                                .withOpacity(0.7),
                          ),
                          child: isLoading
                              ? Loader(color: Colors.white, size: 24)
                              : Text(
                                  locn.verifyOtp,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _closeMigrationDialog() {
    if (_isDialogShowing && mounted) {
      _isDialogShowing = false;
      Navigator.of(context).pop();
    }
  }

  void _showMigrationDialog() {
    if (!_isDialogShowing && mounted) {
      _isDialogShowing = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.85),
        builder: (context) => _migratingDataDialog(),
      );
    }
  }

  Widget _migratingDataDialog() {
    return AlertDialog(
      backgroundColor: AppColors.bgWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.all(32),
      content: WillPopScope(
        onWillPop: () async => false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.sync_alt_rounded,
                  size: 40,
                  color: AppColors.secondary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Loader(),
            const SizedBox(height: 28),
            Text(
              AppLocalizations.of(context)!.migratingData,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.weAreMigratingYourData,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
                height: 1.5,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.secondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200, width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.orange.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.pleaseDontCloseTheApp,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.transferringData,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
