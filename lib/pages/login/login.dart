import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/helpers/country_code_detector.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/pages/account/privacy_policy_page.dart';
import 'package:aboglumbo_bbk_panel/pages/account/terms_and_conditions_page.dart';
import 'package:aboglumbo_bbk_panel/pages/home/home.dart';
import 'package:aboglumbo_bbk_panel/pages/login/bloc/login_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/login/otp.dart';
import 'package:aboglumbo_bbk_panel/pages/login/widgets/language_selector.dart';
import 'package:aboglumbo_bbk_panel/services/notification_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:aboglumbo_bbk_panel/styles/images.dart';
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
          _showSnackBar('Error during login: ${e.toString()}', Colors.red);
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
          message =
              '❌ Biometric error: ${exception.message ?? 'Unknown error'}';
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

  Widget _buildHeaderImage() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              child: Container(
                height: 305,
                width: 256,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
            ),
            Container(
              height: 295,
              width: 278,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(32),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: SizedBox(
                height: 285,
                width: 290,
                child: Image.asset(
                  AppImages.newLogin,

                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ],
        ),
      ),
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
      alignment: Alignment.center,
      padding: const EdgeInsets.only(left: 22, right: 22),
      child: TextFormField(
        controller: _phoneController,
        textInputAction: TextInputAction.done,
        keyboardType: TextInputType.number,

        style: GoogleFonts.dmSans(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
          prefixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🇸🇦', style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        '+966',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
           
        ),
        onFieldSubmitted: (_) => _onLoginPressed(),
      ),
    );
  }

  Widget _buildRememberMeCheckbox() {
    return Center(
      child: CheckboxListTile.adaptive(
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.all(0),
        title: Text(
          AppLocalizations.of(context)?.rememberMe ?? 'Remember Me',
          style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
        ),
        side: const BorderSide(color: Colors.white),
        activeColor: Colors.blue,
        checkColor: Colors.white,
        value: _isRememberMeChecked,
        onChanged: _onRememberMeChanged,
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
            color: Colors.white.withOpacity(0.1),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/fingerPrint.png',
                height: 60,
                width: 60,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(LoginState state) {
    final isLoading = state is LoginLoading;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: SizedBox(
        width: double.maxFinite,
        height: 50,
        child: ElevatedButton(
          onPressed: isLoading ? null : _onLoginPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            disabledBackgroundColor: AppColors.secondary.withOpacity(0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: isLoading
              ? Loader(size: 20, color: Colors.white)
              : Text(
                  AppLocalizations.of(context)?.continueText ?? 'Continue',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
                  "${AppLocalizations.of(context)?.byContinuingYouAgreeToOur ?? ''} ",
              style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white60),
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
              style: GoogleFonts.dmSans(fontSize: 11, color: Colors.blue),
            ),
            TextSpan(
              text: ' ${AppLocalizations.of(context)?.and ?? ''} ',
              style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white60),
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
              style: GoogleFonts.dmSans(fontSize: 11, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
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
              ),
            ),
          );
        } else if (state is OTPSentFailure) {
          _showSnackBar(state.error, Colors.red);
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
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderImage(),
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            AppLocalizations.of(context)?.loginDescription ??
                                '',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                        ),
                        const SizedBox(height: 13),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: LanguageSelectorCard(isInLoginPage: true),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppLocalizations.of(context)?.mobileNumber ?? '',
                          style: GoogleFonts.dmSans(
                            color: Colors.white.withOpacity(.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildPhoneInputField(),
                        const SizedBox(height: 6),
                        _buildRememberMeCheckbox(),
                        const SizedBox(height: 10),
                        _buildLoginButton(state),
                        const SizedBox(height: 20),

                        if (isCheckUserEnableTwoStepVerification &&
                            customerLastUid != null &&
                            customerLastUid!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withOpacity(0.5),
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  AppLocalizations.of(context)?.or ?? 'OR',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withOpacity(0.5),
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildFingerprintAuth(),
                        ],

                        const SizedBox(height: 20),
                        _buildTermsAndPrivacyText(),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ✅ Alternative: Material Design Loading
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
}
