import 'dart:developer';

import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/common_widget/technician_welcome_modal.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/pages/account/account.dart';
import 'package:aboglumbo_bbk_panel/pages/bookings/warranty_page.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/admin_dashboard.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/admin_home.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage_app.dart';
import 'package:aboglumbo_bbk_panel/pages/home/worker/dashboard.dart';
import 'package:aboglumbo_bbk_panel/pages/home/worker/worker_home.dart';
import 'package:aboglumbo_bbk_panel/pages/login/bloc/login_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/login/login.dart';
import 'package:aboglumbo_bbk_panel/services/notification_services.dart';
import 'package:aboglumbo_bbk_panel/services/technician_location_update_service.dart';

import 'package:aboglumbo_bbk_panel/common_widget/animated_expanding_nav_bar.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:aboglumbo_bbk_panel/styles/icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

class Home extends StatefulWidget {
  final String? byPassUid;
  final int? newIndex;
  final String? selectedFilter;
  final bool isNewRegistration;
  const Home({
    super.key,
    this.byPassUid,
    this.newIndex,
    this.selectedFilter,
    this.isNewRegistration = false,
  });

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  int currentIndex = 0;
  String selectedBookingStatus = 'P';

  @override
  void initState() {
    super.initState();
    log('initState');
    log('newIndex: ${widget.newIndex}');
    currentIndex = widget.newIndex ?? 0;
    log('selectedfilter: ${widget.selectedFilter}');
    if (widget.selectedFilter != null) {
      selectedBookingStatus = widget.selectedFilter!;
    } else {
      selectedBookingStatus = 'P';
    }

    // Add observer for app lifecycle
    WidgetsBinding.instance.addObserver(this);

    // Initialize notifications and background services
    Future.delayed(Duration.zero, () async {
      await NotificationServices.initializeNotifications();
      await NotificationServices.setupFCMListeners();
      await NotificationServices.checkForInitialMessage();

      // Initialize background location updates for technicians
      await TechnicianLocationUpdateService.initializeBackgroundLocationUpdates();

      // Update location immediately on app startup
      await TechnicianLocationUpdateService.updateLocationNow();
    });

    if (widget.byPassUid != null && widget.byPassUid!.isNotEmpty) {
      _handleBypassLogin();
    } else {
      final uid = LocalStore.getUID();
      if (uid != null && uid.isNotEmpty) {
        context.read<LoginBloc>().add(LoadWorkerData(uid: uid));
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 App resumed - updating location');
      TechnicianLocationUpdateService.updateLocationNow();
      TechnicianLocationUpdateService.startBackgroundLocationUpdates();
    }
  }

  void _handleBypassLogin() {
    context.read<LoginBloc>().add(LoadWorkerData(uid: widget.byPassUid!));
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        if (state is LoginLoadWorkerDataFailure) {
          return _buildErrorState(context, state.error, locale);
        }

        UserModel userData;
        if (state is LoginSuccess) {
          userData = state.user;
        } else if (state is LoginLoadWorkerData) {
          userData = state.user;
        } else {
          return Scaffold(
            body: Center(child: Loader(color: AppColors.primary)),
          );
        }

        // Handle verification pending state
        if (userData.isVerified != true && userData.isAdmin != true) {
          return _buildVerificationPendingState(context, locale);
        }

        // Show welcome modal for technicians
        if (userData.isAdmin != true &&
            userData.isOnline != true &&
            userData.isVerified == true &&
            !LocalStore.getWelcomeModalShown(userData.uid ?? '')) {
          LocalStore.setWelcomeModalShown(userData.uid ?? '', true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            TechnicianWelcomeModal.show(
              context,
              onEnableAvailability: () {
                Navigator.of(context).pop();
                setState(() => currentIndex = 0);
              },
            );
          });
        }

        // Setup pages based on fixed role
        final List<Widget> pages = userData.isAdmin == true
            ? [
                const AdminDashboardPage(),
                const AdminHome(),
                ManageApp(userData: userData),
                WarrantyPage(workerData: userData, isTechnicianView: false),
                AccountPage(workerData: userData),
              ]
            : [
                DashboardScreen(workerData: userData),
                WorkerHome(selectedIndex: selectedBookingStatus),
                WarrantyPage(workerData: userData, isTechnicianView: true),
                AccountPage(workerData: userData),
              ];

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (currentIndex == 0) {
              _showExitDialog(context, locale);
            } else {
              setState(() => currentIndex = 0);
            }
          },
          child: Scaffold(
            extendBodyBehindAppBar: true,
            extendBody: true,
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: pages[currentIndex],
            ),
            bottomNavigationBar: AnimatedExpandingNavBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) {
                if (index < pages.length) {
                  setState(() => currentIndex = index);
                }
              },
              height: 70,
              selectedItemColor: AppColors.newYellow,
              destinations: [
                AnimatedNavDestination(
                  icon: SvgPicture.asset(AppIcons.homeNav),
                  selectedIcon: SvgPicture.asset(AppIcons.homeNav),
                  label: locale?.dashboard ?? 'Dashboard',
                ),

                if (userData.isAdmin == true)
                  AnimatedNavDestination(
                    icon: const Icon(Icons.format_list_bulleted),
                    selectedIcon: const Icon(Icons.format_list_bulleted),
                    label: locale?.orders ?? 'Orders',
                  ),

                if (userData.isAdmin == true)
                  AnimatedNavDestination(
                    icon: const Icon(Icons.settings_rounded),
                    selectedIcon: const Icon(Icons.settings_rounded),
                    label: locale?.manage ?? 'Manage',
                  )
                else
                  AnimatedNavDestination(
                    icon: const Icon(Icons.format_list_bulleted),
                    selectedIcon: const Icon(Icons.format_list_bulleted),
                    label: locale?.orders ?? 'Orders',
                  ),
                AnimatedNavDestination(
                  icon: const Icon(Icons.verified_user_rounded),
                  selectedIcon: const Icon(Icons.verified_user_rounded),
                  label: locale?.warrantyClaims ?? 'Warranty Claims',
                ),
                AnimatedNavDestination(
                  icon: SvgPicture.asset(AppIcons.profileNav),
                  selectedIcon: SvgPicture.asset(AppIcons.profileNav),
                  label: locale?.account ?? 'Account',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    String error,
    AppLocalizations? locale,
  ) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${locale?.error}: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              ),
              child: Text(locale?.retry ?? 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationPendingState(
    BuildContext context,
    AppLocalizations? locale,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(locale?.account ?? 'Account'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_empty, size: 80, color: AppColors.secondary),
              const SizedBox(height: 24),
              Text(
                locale?.pleaseWaitAccountVerification ??
                    'Please wait for account verification',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                locale?.accountVerificationPending ??
                    'Your account is pending verification.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: Text(locale?.goToLogin ?? 'Go to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context, AppLocalizations? locale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgWhite,
        title: Text(locale?.exitAppTitle ?? 'Exit App'),
        content: Text(
          locale?.exitAppMessage ?? 'Are you sure you want to exit the app?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              locale?.cancel ?? 'Cancel',
              style: const TextStyle(color: Colors.black),
            ),
          ),
          eButton(
            text: locale?.exit ?? 'Exit',
            onPressed: () => Navigator.of(context).pop(true),
            context: context,
            textColor: Colors.white,
            backgroundColor: Colors.red,
          ),
        ],
      ),
    );
  }
}
