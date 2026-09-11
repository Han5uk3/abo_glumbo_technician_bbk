import 'dart:developer';

import 'package:aboglumbo_bbk_panel/common_widget/danger_alerts.dart';
import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/helpers/constants.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/language.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/pages/account/about_us_page.dart';
import 'package:aboglumbo_bbk_panel/pages/account/bloc/account_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/account/edit_profile.dart';
import 'package:aboglumbo_bbk_panel/pages/account/payout_accounts.dart';
import 'package:aboglumbo_bbk_panel/pages/account/privacy_policy_page.dart';
import 'package:aboglumbo_bbk_panel/pages/account/terms_and_conditions_page.dart';
import 'package:aboglumbo_bbk_panel/pages/account/widgets/account_list_tile.dart';
import 'package:aboglumbo_bbk_panel/pages/account/widgets/language_dialog.dart';
import 'package:aboglumbo_bbk_panel/pages/home/worker/contact_bottom_sheet.dart';
import 'package:aboglumbo_bbk_panel/pages/login/login.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/services/app_settings_service.dart';
import 'package:aboglumbo_bbk_panel/services/biometric_service.dart';
import 'package:aboglumbo_bbk_panel/services/notification_services.dart';

import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AccountPage extends StatefulWidget {
  final UserModel? workerData;
  const AccountPage({super.key, this.workerData});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _isBiometricEnabled = false;
  late UserModel? currentWorkerData;
  List<LanguageModel> languages = [
    LanguageModel(code: 'en', name: 'English'),
    LanguageModel(code: 'ar', name: 'عربي'),
    LanguageModel(code: 'ur', name: 'اردو'),
  ];

  bool isMainAdmin = false;

  /// Remote flag from `app_settings/technician_app_v1.showDeleteAccount`.
  /// Created once so rebuilds do not re-subscribe.
  late final Stream<bool> _deleteAccountEnabled;

  @override
  void initState() {
    super.initState();
    final adminData = LocalStore.getCachedAdminData();
    isMainAdmin = adminData?.isCoreAdmin == true;

    final cachedUser = LocalStore.getCachedUserData();
    currentWorkerData = cachedUser ?? widget.workerData;
    _deleteAccountEnabled = AppSettingsService.watchDeleteAccountEnabled();
    _loadBiometricSettings();
  }

  Future<void> _loadBiometricSettings() async {
    final isEnabled = await BiometricService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _isBiometricEnabled = isEnabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AccountBloc, AccountState>(
      listener: (context, state) {
        if (state is UpdateWorkerNotificationLanguageSuccess) {
          if (currentWorkerData != null) {
            setState(() {
              currentWorkerData = currentWorkerData!.copyWith(
                lanCode: state.languageCode,
              );
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.notificationLanguageUpdated ??
                    'Notification language updated successfully',
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: BlocBuilder<AccountBloc, AccountState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.bgWhite,
            body: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  centerTitle: true,
                  floating: false,
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  pinned: true,
                  shape: Border.all(style: BorderStyle.none),
                  title: Text(
                    AppLocalizations.of(context)!.account,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    _buildProfileHeader(),
                    _buildUserInfo(),
                    _buildAccountSection(),
                    _buildGeneralSettings(state),
                    _buildSupportSection(),
                    _buildLegalSection(),
                    _buildDangerZone(),
                    _buildAuthSection(),
                    const SizedBox(height: 106),
                  ]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader() {
    return SizedBox(
      height: AccountPageConstants.profileHeaderHeight,
      child: Stack(
        children: [
          Container(
            width: double.maxFinite,
            height: AccountPageConstants.primaryContainerHeight,
            decoration: BoxDecoration(color: AppColors.primary),
            child: Stack(
              children: [
                SizedBox(
                  width: double.maxFinite,
                  height: AccountPageConstants.primaryContainerHeight,
                  child: Image.asset(
                    "assets/images/appbarbg.png",
                    fit: BoxFit.fitHeight,
                    repeat: ImageRepeat.repeat,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CircleAvatar(
              radius: AccountPageConstants.avatarRadius,
              backgroundColor: AppColors.yellow,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: CircleAvatar(
                  radius: AccountPageConstants.avatarRadius - 4,
                  backgroundColor: AppColors.yellow,
                  child: ClipOval(
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: currentWorkerData?.profileUrl != null
                          ? CachedNetworkImage(
                              imageUrl: currentWorkerData!.profileUrl!,
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                              placeholder: (context, url) => Center(
                                child: Loader(
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              ),
                            )
                          : Center(
                              child: Text(
                                currentWorkerData?.name
                                        ?.substring(0, 1)
                                        .toUpperCase() ??
                                    '',
                                style: TextStyle(
                                  fontSize: AccountPageConstants.avatarFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Padding(
      padding: AccountPageConstants.horizontalPadding.copyWith(top: 30),
      child: Column(
        children: [
          Text(
            currentWorkerData?.name ?? '',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            currentWorkerData?.email ?? '',
            style: TextStyle(fontSize: 10, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AccountPageConstants.sectionSpacing),
          if (currentWorkerData?.isAdmin != true)
            AccountListTile.withArrow(
              leading: const Icon(Icons.person_outline),
              title: AppLocalizations.of(context)?.profileManagement ?? '',
              onTap: () async {
                final updatedUser = await Navigator.push<UserModel>(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditProfile(workerData: currentWorkerData),
                  ),
                );

                if (updatedUser != null) {
                  setState(() {
                    currentWorkerData = updatedUser;
                  });
                }
              },
            ),
          if (currentWorkerData?.isAdmin != true)
            AccountListTile.withArrow(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: AppLocalizations.of(context)?.payoutAccounts ?? '',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PayoutAccountsPage(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGeneralSettings(AccountState state) {
    final currentLanguage = state.locale.languageCode;
    final displayLanguage = currentLanguage == 'ar'
        ? 'عربي'
        : currentLanguage == 'ur'
        ? 'اردو'
        : 'English';

    final currentNotifLanguage = currentWorkerData?.lanCode ?? 'en';
    final displayNotifLanguage = currentNotifLanguage == 'ar'
        ? 'عربي'
        : currentNotifLanguage == 'ur'
        ? 'اردو'
        : 'English';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          AccountListTile.withText(
            leading: const Icon(Icons.translate),
            title: AppLocalizations.of(context)?.language ?? 'Language',
            trailingText: displayLanguage,
            onTap: () => _showLanguageDialog(false),
          ),
          AccountListTile.withText(
            leading: const Icon(Icons.language),
            title:
                AppLocalizations.of(context)?.notificationLanguage ??
                'Notification Language',
            trailingText: displayNotifLanguage,
            onTap: () => _showLanguageDialog(true),
          ),
          _buildSecuritySettings(),
        ],
      ),
    );
  }

  Widget _buildSecuritySettings() {
    return AccountListTile(
      leading: const Icon(Icons.fingerprint),
      title: AppLocalizations.of(context)?.bioMetricAuthentication ?? '',
      trailing: SizedBox(
        width: 50,
        height: 40,
        child: FittedBox(
          fit: BoxFit.fill,
          child: Switch(
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: Colors.grey.shade300,
            value: _isBiometricEnabled,
            onChanged: _handleBiometricToggle,
          ),
        ),
      ),
    );
  }

  Widget _buildSupportSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          AccountListTile.withArrow(
            leading: const Icon(Icons.info_outline),
            title: AppLocalizations.of(context)?.aboutUs ?? '',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AboutUsPage()),
            ),
          ),
          AccountListTile.withArrow(
            leading: const Icon(Icons.support_agent),
            title:
                AppLocalizations.of(context)?.contactSupport ??
                'Contact Support',
            onTap: _showSupportBottomSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          AccountListTile.withArrow(
            leading: const Icon(Icons.description_outlined),
            title: AppLocalizations.of(context)?.termsAndConditions ?? '',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    const TermsAndConditionsPage(isFromLogin: false),
              ),
            ),
          ),
          AccountListTile.withArrow(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: AppLocalizations.of(context)?.privacyPolicy ?? '',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const PrivacyPolicyPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    if (isMainAdmin) return const SizedBox.shrink();
    return StreamBuilder<bool>(
      stream: _deleteAccountEnabled,
      initialData: false,
      builder: (context, snapshot) {
        // Stays hidden unless the remote flag is explicitly enabled.
        if (snapshot.data != true) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: AccountListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            textcolor: Colors.red,
            title: AppLocalizations.of(context)?.deleteAccount ?? '',
            onTap: _showDeleteAccountConfirmation,
            dense: true,
          ),
        );
      },
    );
  }

  Widget _buildAuthSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: AccountListTile(
        leading: const Icon(Icons.logout),
        title: AppLocalizations.of(context)?.logout ?? 'Logout',
        onTap: () => AccountActionDialogs.showLogoutConfirmation(
          context,
          onConfirm: _handleLogout,
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      await AppServices.clearFCMToken();
      await NotificationServices.deleteFCMToken();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing FCM tokens during logout: $e');
      }
    }

    final lastUid = LocalStore.getUID();
    bool keepFirebaseAuth = false;
    if (lastUid != null) {
      keepFirebaseAuth = LocalStore.getBiometricAuthEnabled(lastUid);
    }

    // This handles clearing UID, cached data, and setting logout status to true
    await LocalStore.clearAllAuthData();

    try {
      if (!keepFirebaseAuth) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error signing out from Firebase Auth: $e');
      }
    }

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _showSupportBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return const ContactBottomSheet();
      },
    );
  }

  Future _showLanguageDialog(bool isForNotification) async {
    final currentLanguage = isForNotification
        ? (currentWorkerData?.lanCode ?? 'en')
        : LocalStore.getUserlanguage();

    await showDialog(
      context: context,
      builder: (context) {
        return LanguageSelectionDialog(
          title:
              AppLocalizations.of(context)?.selectLanguage ?? 'Select Language',
          currentLanguageCode: currentLanguage,
          onEnglishSelected: () => _updateLanguage('en', isForNotification),
          onArabicSelected: () => _updateLanguage('ar', isForNotification),
          onUrduSelected: () => _updateLanguage('ur', isForNotification),
        );
      },
    );
  }

  void _updateLanguage(String code, bool isForNotification) {
    if (isForNotification) {
      context.read<AccountBloc>().add(
        UpdateWorkerNotificationLanguageEvent(code),
      );
    } else {
      context.read<AccountBloc>().add(ChangeLanguageEvent(code));
    }
  }

  Future<void> _showDeleteAccountConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.bgWhite,
          actionsAlignment: MainAxisAlignment.start,
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(dialogContext)?.deleteAccount ??
                      'Delete Account?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(dialogContext)?.deleteAccountWarning ??
                    'This action cannot be undone. All your data will be permanently deleted.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(
                                  dialogContext,
                                )?.whatWillBeDeleted ??
                                'What will be deleted:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildDeleteItem(
                      dialogContext,
                      AppLocalizations.of(dialogContext)?.personalInfo ??
                          'Personal information',
                    ),
                    _buildDeleteItem(
                      dialogContext,
                      AppLocalizations.of(dialogContext)?.bookingHistory ??
                          'Booking history',
                    ),
                    _buildDeleteItem(
                      dialogContext,
                      AppLocalizations.of(dialogContext)?.documents ??
                          'Uploaded documents',
                    ),
                    _buildDeleteItem(
                      dialogContext,
                      AppLocalizations.of(dialogContext)?.allData ??
                          'All associated data',
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            eButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              text: AppLocalizations.of(dialogContext)?.cancel ?? 'Cancel',
              context: dialogContext,
              textColor: Colors.black,
              backgroundColor: AppColors.bgWhite,
            ),
            eButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              text:
                  AppLocalizations.of(dialogContext)?.deleteAccount ??
                  'Delete Account',
              context: dialogContext,
              textColor: Colors.white,
              backgroundColor: Colors.red,
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _deleteAccount();
    }
  }

  Widget _buildDeleteItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.userNotFound ?? 'User not found',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
              backgroundColor: AppColors.bgWhite,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 24,
                    child: Loader(size: 24, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    AppLocalizations.of(dialogContext)?.deletingAccount ??
                        'Deleting account...',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    try {
      final uid = user.uid;

      try {
        await AppServices.clearFCMToken();
        await NotificationServices.deleteFCMToken();
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error clearing FCM tokens during account deletion: $e');
        }
      }

      // Clear local biometric settings and credentials immediately to guarantee biometrics are disabled
      await LocalStore.clearLogoutStatus();
      await LocalStore.putRememberMe(false);
      await LocalStore.clearRememberedPhone();
      await LocalStore.clearUID();
      await LocalStore.clearCachedUserData();
      await LocalStore.clearBiometricAuthEnabled(uid);
      await LocalStore.clearLastValidUID();

      await AppFirestore.usersCollectionRef.doc(uid).delete();
      await user.delete();

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      String errorMessage;
      switch (e.code) {
        case 'requires-recent-login':
          errorMessage =
              AppLocalizations.of(context)?.requiresRecentLogin ??
              'For security reasons, please log out and log back in before deleting your account.';
          break;
        case 'too-many-requests':
          errorMessage =
              AppLocalizations.of(context)?.tooManyRequests ??
              'Too many requests. Please try again later.';
          break;
        case 'network-request-failed':
          errorMessage =
              AppLocalizations.of(context)?.networkError ??
              'Network error. Please check your connection.';
          break;
        case 'user-disabled':
          errorMessage =
              AppLocalizations.of(context)?.userDisabled ??
              'This user account has been disabled.';
          break;
        case 'user-not-found':
          errorMessage =
              AppLocalizations.of(context)?.userNotFound ??
              'User account not found.';
          break;
        default:
          errorMessage =
              AppLocalizations.of(context)?.failedToDeleteAccount ??
              'Failed to delete account: ${e.message}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.failedToDeleteAccount ??
                  'Failed to delete account: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleBiometricToggle(bool value) async {
    if (value) {
      final authenticated = await BiometricService.authenticate(context);
      if (authenticated && mounted) {
        setState(() => _isBiometricEnabled = true);
        BiometricService.setBiometricEnabled(true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.biometricEnabled ??
                    'Biometric authentication enabled',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            backgroundColor: AppColors.bgWhite,
            actionsAlignment: MainAxisAlignment.start,
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(dialogContext)?.disableBiometric ??
                        'Disable Biometric?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(dialogContext)?.disableBiometricWarning ??
                      'Disabling biometric authentication will prevent you from logging in using fingerprint or face recognition.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(
                                dialogContext,
                              )?.youWillNeedPhoneOtp ??
                              'You will need to use your phone number and OTP to login.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              eButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                text: AppLocalizations.of(dialogContext)?.cancel ?? 'Cancel',
                context: dialogContext,
                textColor: Colors.black,
                backgroundColor: AppColors.bgWhite,
              ),
              eButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                text: AppLocalizations.of(dialogContext)?.disable ?? 'Disable',
                context: dialogContext,
                textColor: Colors.white,
                backgroundColor: Colors.red,
              ),
            ],
          );
        },
      );

      if (confirmed == true && mounted) {
        setState(() => _isBiometricEnabled = false);
        BiometricService.setBiometricEnabled(false);
        log('Biometric authentication disabled');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.biometricDisabled ??
                    'Biometric authentication disabled',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }
}
