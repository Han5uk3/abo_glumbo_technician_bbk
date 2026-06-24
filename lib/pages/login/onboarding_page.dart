import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/pages/login/widgets/language_selector.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:aboglumbo_bbk_panel/pages/login/login.dart';
import 'package:aboglumbo_bbk_panel/styles/app_color.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  void _navigateToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  String _getTitle(BuildContext context) {
    final locale = AppLocalizations.of(context)?.localeName;
    if (locale == 'ar') {
      return "مرحباً بك، أيها الفني!";
    } else if (locale == 'ur') {
      return "خوش آمدید، ٹیکنیشن!";
    } else {
      return "Welcome, Technician!";
    }
  }

  String _getDescription(BuildContext context) {
    final locale = AppLocalizations.of(context)?.localeName;
    if (locale == 'ar') {
      return "يمكنك تصفح الطلبات المتاحة وتقديم خدمات احترافية للعملاء.";
    } else if (locale == 'ur') {
      return "آپ دستیاب درخواستیں دیکھ سکتے ہیں اور صارفین کو پیشہ ورانہ خدمات فراہم کر سکتے ہیں۔";
    } else {
      return "You can browse available requests and provide professional services to customers.";
    }
  }

  String _getBtnText(BuildContext context) {
    final locale = AppLocalizations.of(context)?.localeName;
    if (locale == 'ar') {
      return "ابدأ الآن";
    } else if (locale == 'ur') {
      return "شروع کریں";
    } else {
      return "Get Started";
    }
  }

  String _getVerifiedText(BuildContext context) {
    final locale = AppLocalizations.of(context)?.localeName;
    if (locale == 'ar') {
      return "تصفح وقبول الطلبات";
    } else if (locale == 'ur') {
      return "درخواستیں براؤز کریں اور قبول کریں";
    } else {
      return "Browse & Accept Requests";
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    const onboardBgColor = Color(0xFF081C5B);

    return Scaffold(
      backgroundColor: onboardBgColor,
      body: Stack(
        children: [
          // Onboarding Screen Content
          Positioned.fill(
            child: Container(
              color: onboardBgColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Image/Icon Section
                  SizedBox(
                    height: screenHeight * 0.37,
                    child: Stack(
                      children: [
                        Center(
                          child: Container(
                            height: screenHeight * 0.3,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white10,
                            ),
                          ),
                        ),
                        Center(
                          child: SizedBox(
                            height: screenHeight * 0.3,
                            width: screenWidth,
                            child: Image.asset(
                              "assets/images/newimagesonboard.jpeg",
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        // Glassmorphic badge over the image
                        Positioned(
                          bottom: 0,
                          left: screenWidth * 0.16,
                          right: screenWidth * 0.16,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 13, sigmaY: 13),
                              child: Container(
                                width: screenWidth * 0.8,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      flex: 1,
                                      child: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: Colors.white,
                                        child: Icon(
                                          size: 14,
                                          Icons.verified_user,
                                          color: Color(0xFF081C5B),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 5,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4.0,
                                        ),
                                        child: Text(
                                          _getVerifiedText(context),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _getTitle(context),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _getDescription(context),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.85),
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),

          // Header Overlay Accent
          Positioned(
            top: 0,
            child: Container(
              height: screenHeight * 0.3,
              width: screenWidth,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                borderRadius: BorderRadius.only(
                  bottomLeft: Directionality.of(context) == TextDirection.ltr
                      ? const Radius.circular(12)
                      : const Radius.circular(0),
                  bottomRight: Directionality.of(context) == TextDirection.ltr
                      ? const Radius.circular(0)
                      : const Radius.circular(12),
                ),
              ),
            ),
          ),

          // Bottom Action Section
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05)),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
              margin: const EdgeInsets.fromLTRB(0, 24, 0, 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _navigateToLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bgWhite,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 10,
                  ),
                  child: Text(
                    _getBtnText(context),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Skip/Language selector card in top right/left
          Positioned(
            top: kToolbarHeight + 6,
            right: Directionality.of(context) == TextDirection.ltr ? 16 : null,
            left: Directionality.of(context) == TextDirection.ltr ? null : 16,
            child: const LanguageSelectorCard(isInLoginPage: false),
          ),
        ],
      ),
    );
  }
}
