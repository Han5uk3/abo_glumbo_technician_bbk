import 'dart:async';
import 'dart:io';

import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/services/auth_services.dart';
import 'package:aboglumbo_bbk_panel/services/otp_api.dart';
import 'package:aboglumbo_bbk_panel/services/sms_autofill_service.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class OtpPage extends StatefulWidget {
  final String? phoneNumber;
  final String? verificationId;
  final int? resendToken;
  final bool? isFromProfile;

  /// The account whose number is being changed, when [isFromProfile] is true.
  final String? expectedUid;
  const OtpPage({
    super.key,
    this.phoneNumber,
    this.verificationId,
    this.resendToken,
    this.isFromProfile,
    this.expectedUid,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  bool isLoading = false;
  bool isResendingOtp = false;
  bool _isSmsAutofillListening = false;
  int resendSeconds = 60;
  Timer? _timer;
  int _smsListenGeneration = 0;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String? _verificationId;
  int? _resendToken;
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
      return;
    }
    if (isResendingOtp) return;


    setState(() {
      isResendingOtp = true;
    });

    try {
      await AuthServices().resendOTP(
        phoneNumber: widget.phoneNumber ?? '',
        resendToken: _resendToken,
        currentVerificationId: _verificationId,
        purpose: widget.isFromProfile == true
            ? OtpPurpose.changePhone
            : OtpPurpose.login,
        locale: Localizations.localeOf(context).languageCode,
        expectedUid: widget.expectedUid,
        onCodeSent: (verificationId, {int? resendToken}) {

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
            _startSmsAutofillListener();
          }
        },
        onAutoRetrievalTimeout: (verificationId) {

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
    } catch (e) {

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
      // Always reset the loading state, regardless of success or failure
      if (mounted) {
        setState(() {
          isResendingOtp = false;
        });
      }
    }
  }

  void verifyOtp() async {
    if (isLoading) return;

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

    setState(() {
      isLoading = true;
    });

    try {
      if (widget.isFromProfile == true) {
        // The account moves to the verified number on the same UID, and the
        // user stays signed in.
        final newPhone = await AuthServices().confirmPhoneChange(
          verificationId: verificationId,
          otp: otp,
          expectedUid: widget.expectedUid ?? '',
        );
        if (!mounted) return;
        setState(() => isLoading = false);
        Navigator.pop(context, newPhone);
        return;
      }

      final UserCredential? userCredential = await AuthServices().verifyOTP(
        context,
        otp,
        verificationId: verificationId,
        smsCode: otp,
        phoneNumber: widget.phoneNumber ?? '',
      );
      if (userCredential == null || !mounted) return;
      await AuthServices().checkUser(
        userCredential: userCredential,
        context: context,
      );
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
            case 'phone-already-in-use':
              errorMessage =
                  AppLocalizations.of(context)?.phoneNumberAlreadyExists ??
                  'Phone number already exists';
              break;
            case 'requires-recent-login':
              errorMessage =
                  AppLocalizations.of(context)?.signInAgainToChangePhone ??
                  'Please sign in again to change your phone number.';
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

  /// Android only: Google asks the user to share the OTP SMS, then the code
  /// is filled in and verified. On iOS the keyboard offers the code from
  /// Messages instead, through Pinput's default oneTimeCode autofill hint.
  /// Called when the page opens (first send) and after every resend.
  void _startSmsAutofillListener() {
    if (!Platform.isAndroid || !mounted) return;

    setState(() {
      _isSmsAutofillListening = true;
    });

    _listenForSmsCode(++_smsListenGeneration);
  }

  /// Listen for SMS code and auto-fill the OTP field
  void _listenForSmsCode(int generation) async {
    try {
      final smsCode = await _smsAutofillService.listenForSms(
        timeout: const Duration(minutes: 5),
      );

      // A resend restarted listening; the newer listener owns the UI.
      if (!mounted || generation != _smsListenGeneration) return;

      setState(() {
        _isSmsAutofillListening = false;
      });

      if (smsCode != null && smsCode.isNotEmpty) {
        _otpController.text = smsCode;

        // Clear the form to reset validation
        _formKey.currentState?.reset();

        // Automatically verify the OTP after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          verifyOtp();
        }
      }
    } catch (e) {
      if (mounted && generation == _smsListenGeneration) {
        setState(() {
          _isSmsAutofillListening = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
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
        absorbing: isLoading,
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
                                // Keyboard up on open, so iOS can offer the
                                // code from Messages without a tap first.
                                autofocus: true,
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
}
