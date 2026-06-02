import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/helpers/country_code_detector.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/pages/account/privacy_policy_page.dart';
import 'package:aboglumbo_bbk_panel/pages/account/terms_and_conditions_page.dart';
import 'package:aboglumbo_bbk_panel/pages/home/home.dart';
import 'package:aboglumbo_bbk_panel/pages/login/bloc/login_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/login/otp.dart';
import 'package:aboglumbo_bbk_panel/pages/login/signup.dart';
import 'package:aboglumbo_bbk_panel/pages/login/widgets/language_selector.dart';
import 'package:aboglumbo_bbk_panel/services/notification_services.dart';
import 'package:aboglumbo_bbk_panel/styles/app_color.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart' as localcolor;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/error_codes.dart' as local_auth_error;
import 'package:local_auth/local_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  bool _isRememberMeChecked = false;
  int? _resendToken;
  bool isCheckUserEnableTwoStepVerification = false;
  String? customerLastUid;
  bool isUserLogout = false;
  bool _isBiometricLoading = false;
  String? _detectedCountryCode;
  String? _displayCountryCode;
  String? _detectedFlag;

  @override
  void initState() {
    super.initState();
    customerLastUid = LocalStore.getLastValidUID();

    // ✅ Check biometric with last valid UID
    isCheckUserEnableTwoStepVerification = LocalStore.getBiometricAuthEnabled(
      customerLastUid ?? '',
    );

    isUserLogout = LocalStore.getLogoutStatus();
    _isRememberMeChecked = LocalStore.getRememberMe();

    if (_isRememberMeChecked) {
      _phoneController.text = LocalStore.getRememberedPhone() ?? '';
    } else {
      _phoneController.clear();
    }

    // Initialize notifications explicitly
    Future.delayed(Duration.zero, () async {
      await NotificationServices.initializeNotifications();
      await NotificationServices.setupFCMListeners();
      await NotificationServices.checkForInitialMessage();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _onLoginPressed() async {
    if (_formKey.currentState!.validate()) {
      final phoneNumber = _phoneController.text.trim();

      if (phoneNumber.length < 9) {
        _showSnackBar(
          AppLocalizations.of(context)?.pleaseEnterAValidPhoneNumber ??
              'Please enter a valid phone number',
          AppColors.yellow,
        );
        return;
      }

      // Format phone number with country code
      final formattedPhoneNumber = CountryCodeDetector.formatPhoneNumber(
        phoneNumber,
        countryCode: _detectedCountryCode,
      );
      debugPrint('📱 [PANEL LOGIN] Original: $phoneNumber');
      debugPrint('📱 [PANEL LOGIN] Formatted: $formattedPhoneNumber');

      // Save phone if remember me is checked
      if (_isRememberMeChecked) {
        await LocalStore.rememberPhone(phoneNumber);
      } else {
        await LocalStore.clearRememberedPhone();
      }

      if (mounted) {
        context.read<LoginBloc>().add(
          SendOTPPressed(context: context, phoneNumber: formattedPhoneNumber),
        );
      }
    }
  }

  void _onRememberMeChanged(bool? value) {
    setState(() {
      _isRememberMeChecked = value ?? false;
    });

    LocalStore.putRememberMe(_isRememberMeChecked);

    if (_isRememberMeChecked) {
      final phone = _phoneController.text.trim();
      if (phone.isNotEmpty) {
        LocalStore.rememberPhone(phone);
      }
    } else {
      LocalStore.clearRememberedPhone();
    }
  }

  void _byPassUsingBioAuth(BuildContext context) async {
    final auth = LocalAuthentication();
    try {
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      bool isDeviceSupported = await auth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        _showSnackBar(
          AppLocalizations.of(context)?.biometricNotSupported ??
              'Biometric authentication is not supported on this device.',
          Colors.red,
        );
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason:
            AppLocalizations.of(context)?.pleaseAuthenticateToContinue ??
            'Please authenticate to continue',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        // ✅ Show loading overlay
        if (mounted) {
          setState(() {
            _isBiometricLoading = true;
          });
        }

        try {
          if (FirebaseAuth.instance.currentUser == null) {
            await FirebaseAuth.instance.signInAnonymously();
          }

          // Refresh FCM token after biometric login
          await NotificationServices.refreshFCMToken();

          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => Home(byPassUid: customerLastUid),
              ),
              (route) => false,
            );
          }
        } catch (e) {
          // ✅ Hide loading on error
          if (mounted) {
            setState(() {
              _isBiometricLoading = false;
            });
          }
          _showSnackBar(
            '${AppLocalizations.of(context)?.errorDuringLogin ?? 'Error during login'}: ${e.toString()}',
            Colors.red,
          );
        }
      } else {
        _showSnackBar(
          AppLocalizations.of(context)?.authenticationFailed ??
              '❌ Authentication failed',
          Colors.red,
        );
      }
    } on PlatformException catch (exception) {
      String message = '';
      switch (exception.code) {
        case local_auth_error.notAvailable:
        case local_auth_error.passcodeNotSet:
        case local_auth_error.notEnrolled:
          message =
              AppLocalizations.of(context)?.biometricNotAvailable ??
              '❌ Biometric authentication is not available on this device.';
          break;
        case local_auth_error.lockedOut:
        case local_auth_error.permanentlyLockedOut:
          message =
              AppLocalizations.of(context)?.biometricTemporarilyLocked ??
              '🔒 Too many failed attempts. Biometric is temporarily locked.';
          break;
        default:
          if (exception.message?.toLowerCase().contains('canceled') == true) {
            return;
          }
          final errorPrefix = AppLocalizations.of(context)?.biometricError ?? '❌ Biometric error';
          final unknownError = AppLocalizations.of(context)?.unknownError ?? 'Unknown error';
          message =
              '$errorPrefix: ${exception.message ?? unknownError}';
      }

      if (message.isNotEmpty) {
        _showSnackBar(message, Colors.red);
      }
    } catch (e) {
      _showSnackBar(
        AppLocalizations.of(context)?.unexpectedErrorOccurred ??
            '❌ Unexpected error occurred',
        Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is OTPSentSuccess) {
          _showSnackBar(
            AppLocalizations.of(context)?.otpSentSuccessfully ??
                'OTP sent successfully',
            Colors.green,
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpPage(
                phoneNumber: CountryCodeDetector.formatPhoneNumber(
                  _phoneController.text.trim(),
                  countryCode: "SA",
                ),
                verificationId: state.verificationId,
                resendToken: state.resendToken,
              ),
            ),
          );
        } else if (state is OTPSentFailure) {
          String errorMessage;
          switch (state.error) {
            case 'too-many-requests':
              errorMessage = AppLocalizations.of(context)?.tooManyRequests ??
                  'Too many requests. Please wait and try again.';
              break;
            case 'invalid-phone-number':
              errorMessage = AppLocalizations.of(context)?.pleaseEnterAValidPhoneNumber ??
                  'Please enter a valid phone number';
              break;
            case 'quota-exceeded':
              errorMessage = AppLocalizations.of(context)?.quotaExceeded ??
                  'SMS quota exceeded. Try again later.';
              break;
            case 'network-request-failed':
              errorMessage = AppLocalizations.of(context)?.networkError ??
                  'Network error. Please check your connection.';
              break;
            case 'internal-error':
              errorMessage = AppLocalizations.of(context)?.internalError ??
                  'An internal error occurred. Please try again later.';
              break;
            case 'timeout':
              errorMessage = AppLocalizations.of(context)?.timedOut ??
                  'Timed Out';
              break;
            default:
              errorMessage = state.error;
          }
          _showSnackBar(errorMessage, Colors.red);
        } else if (state is OTPVerifiedForRegistration) {
          // No account found → navigate to create account page
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => Signup(uid: state.uid),
            ),
            (route) => false,
          );
        } else if (state is LoginFailure) {
          String errorMessage;
          switch (state.error) {
            case 'too-many-requests':
              errorMessage =
                  AppLocalizations.of(context)?.tooManyRequests ??
                  'Too many attempts. Please wait and try again.';
              break;
            case 'invalid-phone-number':
              errorMessage =
                  AppLocalizations.of(context)?.pleaseEnterAValidPhoneNumber ??
                  'Please enter a valid phone number';
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
            case 'internal-error':
              errorMessage =
                  AppLocalizations.of(context)?.internalError ??
                  'An internal error occurred. Please try again later.';
              break;
            case 'invalid-verification-code':
              errorMessage =
                  AppLocalizations.of(context)?.invalidOtpCode ??
                  'Invalid OTP code';
              break;
            default:
              errorMessage = state.error;
          }
          _showSnackBar(errorMessage, Colors.red);
        }
      },
      builder: (context, state) {
        return Stack(
          children: [
            Scaffold(
              backgroundColor: AppColors.primary,
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
              ),
              body: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Top Image Container
                      Container(
                        height: MediaQuery.of(context).size.height * 0.27,
                        color: AppColors.primary,
                        width: MediaQuery.of(context).size.width,
                        child: Center(
                          child: SizedBox(
                            height: 80,
                            width: 80,
                            child: Image.asset(
                              'assets/images/app_icon_new.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      // Bottom Container with Border Radius
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          constraints: BoxConstraints(
                            minHeight:
                                MediaQuery.of(context).size.height * 0.73,
                          ),
                          padding: const EdgeInsets.all(15.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.login,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: LanguageSelectorCard(
                                      isInLoginPage: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(
                                          context,
                                        )?.mobileNumber ??
                                        '',
                                    style: GoogleFonts.dmSans(
                                      color: Colors.black.withOpacity(.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  _buildPhoneInputField(),
                                  const SizedBox(height: 10),
                                  _buildRememberMeCheckbox(),
                                  const SizedBox(height: 20),
                                  _buildLoginButton(state),
                                  const SizedBox(height: 20),
                                  _buildTermsAndPrivacyText(),
                                  if (isCheckUserEnableTwoStepVerification &&
                                      customerLastUid != null &&
                                      customerLastUid!.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: Colors.grey.withOpacity(0.5),
                                            thickness: 1,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: Text(
                                            AppLocalizations.of(context)?.or ??
                                                'OR',
                                            style: GoogleFonts.dmSans(
                                              color: Colors.grey.withOpacity(
                                                0.7,
                                              ),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: Colors.grey.withOpacity(0.5),
                                            thickness: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    _buildFingerprintAuth(),
                                  ],
                                  const SizedBox(height: 60),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_isBiometricLoading)
              Material(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 250),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 32,
                          child: Loader(size: 28, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            AppLocalizations.of(context)?.loggingIn ??
                                'Logging in...',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPhoneInputField() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.1), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🇸🇦', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  "+966",
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 24,
                width: 1,
                color: Colors.black.withOpacity(0.1),
              ),
              const SizedBox(width: 12),
            ],
          ),
          Expanded(
            child: TextFormField(
              controller: _phoneController,
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.number,
              textAlignVertical: TextAlignVertical.center,
              style: GoogleFonts.dmSans(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: '5XXXXXXXX',
                hintStyle: GoogleFonts.dmSans(
                  color: Colors.black.withOpacity(0.3),
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
              onFieldSubmitted: (_) => _onLoginPressed(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRememberMeCheckbox() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: _isRememberMeChecked,
            onChanged: _onRememberMeChanged,
            activeColor: AppColors.primary,
            side: BorderSide(color: Colors.black.withOpacity(0.4), width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _onRememberMeChanged(!_isRememberMeChecked),
          child: Text(
            AppLocalizations.of(context)?.rememberMe ?? 'Remember me',
            style: GoogleFonts.dmSans(
              color: Colors.black.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(LoginState state) {
    final isLoading = state is LoginLoading;
    return SizedBox(
      height: 54,
      width: double.maxFinite,
      child: ElevatedButton(
        onPressed: isLoading ? null : _onLoginPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: localcolor.AppColors.primary,
          disabledBackgroundColor: localcolor.AppColors.primary.withOpacity(
            0.6,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: isLoading
            ? Loader(size: 20, color: Colors.white)
            : Text(
                AppLocalizations.of(context)?.continueText ?? '',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildTermsAndPrivacyText() {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: <TextSpan>[
            TextSpan(
              text:
                  "${AppLocalizations.of(context)?.byContinuingYouAgreeToOur ?? ''}\n ",
              style: GoogleFonts.dmSans(fontSize: 10, color: Colors.black),
            ),
            TextSpan(
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          const TermsAndConditionsPage(isFromLogin: true),
                    ),
                  );
                },
              text: AppLocalizations.of(context)?.termsOfUse ?? '',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
            TextSpan(
              text: " ${AppLocalizations.of(context)!.and} ",
              style: GoogleFonts.dmSans(fontSize: 10, color: Colors.black),
            ),
            TextSpan(
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyPage(),
                    ),
                  );
                },
              text: AppLocalizations.of(context)?.privacyPolicy ?? '',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFingerprintAuth() {
    return Center(
      child: GestureDetector(
        onTap: () => _byPassUsingBioAuth(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.05),
            border: Border.all(color: Colors.black.withOpacity(0.1), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/fingerPrint.png',
                height: 60,
                width: 60,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
