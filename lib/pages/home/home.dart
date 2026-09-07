import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:aboglumbo_bbk_panel/pages/login/widgets/language_selector.dart';
import 'package:aboglumbo_bbk_panel/pages/home/worker/contact_bottom_sheet.dart';
import 'package:aboglumbo_bbk_panel/services/technician_location_update_service.dart';
import 'package:aboglumbo_bbk_panel/pages/account/reupload_docs.dart';
import 'package:aboglumbo_bbk_panel/common_widget/animated_expanding_nav_bar.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:aboglumbo_bbk_panel/styles/icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// The route of the Home currently in the navigator, or null when there is
  /// none (or its route has since left the stack).
  ///
  /// Notification taps used to reach the chat screen by replacing the whole
  /// stack with a fresh Home and pushing the chat on top of it. That threw away
  /// a live Home and re-ran its entire startup - a GPS fix, a user-data refresh
  /// and the FCM setup - only to land the user back where they already were.
  /// Holding the route object lets a tap pop down to the existing Home instead,
  /// with no route name to keep in sync across the many places Home is built.
  static ModalRoute<dynamic>? get activeRoute {
    final route = _HomeState._activeRoute;
    return (route != null && route.isActive) ? route : null;
  }
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  static ModalRoute<dynamic>? _activeRoute;
  ModalRoute<dynamic>? _route;

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
      // 1. Update location immediately on app startup
      if (mounted) {
        if (!LocalStore.isCurrentUserAdmin()) {
          debugPrint('🚀 Initializing location update on Home launch');
          await TechnicianLocationUpdateService.updateLocationNow(
            context: context,
          );
        } else {
          debugPrint(
            'ℹ️ User is admin, skipping location update on Home launch',
          );
        }
        if (mounted) {
          context.read<LoginBloc>().add(RefreshUserData());
        }
      }

      // 2. Initialize other services
      await NotificationServices.initializeNotifications();
      await NotificationServices.setupFCMListeners();
      await NotificationServices.checkForInitialMessage();
      if (!LocalStore.isCurrentUserAdmin()) {
        await TechnicianLocationUpdateService.initializeBackgroundLocationUpdates();
      }
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
    _activeRoute = _route;
  }

  @override
  void dispose() {
    // Only clear the shared slot if it is still ours. When two Homes are
    // stacked, the newer one owns it and must keep it when the older unwinds.
    if (identical(_activeRoute, _route)) {
      _activeRoute = null;
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      if (!LocalStore.isCurrentUserAdmin()) {
        debugPrint('🔄 App resumed - updating location');
        TechnicianLocationUpdateService.updateLocationNow(
          context: context,
        ).then((_) {
          if (mounted) {
            context.read<LoginBloc>().add(RefreshUserData());
          }
        });
        TechnicianLocationUpdateService.startBackgroundLocationUpdates();
      } else {
        debugPrint('ℹ️ App resumed - user is admin, refreshing user data only');
        if (mounted) {
          context.read<LoginBloc>().add(RefreshUserData());
        }
      }
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
            backgroundColor: AppColors.bgWhite,
            body: Center(child: Loader(color: AppColors.primary)),
          );
        }

        // Handle verification pending, blocked, or rejected states
        if (userData.isAdmin != true) {
          if (userData.isBlocked == true) {
            return _buildBlockedState(context, userData, locale);
          }
          if (userData.isVerified != true) {
            // Case 1: Rejected and haven't re-uploaded yet
            if (userData.rejectionReason != null &&
                userData.rejectionReason!.isNotEmpty &&
                userData.isDocsPendingReview != true) {
              return _buildRejectedState(context, userData, locale);
            }
            // Case 2: Just registered OR just re-uploaded (waiting for admin)
            return _buildVerificationPendingState(context, locale);
          }
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
              technicianName: userData.name ?? '',
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
                AdminDashboardPage(
                  onNavigate: (index, {bookingStatus}) {
                    setState(() {
                      currentIndex = index;
                      if (bookingStatus != null) {
                        selectedBookingStatus = bookingStatus;
                      }
                    });
                  },
                ),
                AdminHome(initialStatus: selectedBookingStatus),
                ManageApp(userData: userData),
                WarrantyPage(workerData: userData, isTechnicianView: false),
                AccountPage(workerData: userData),
              ]
            : [
                DashboardScreen(
                  workerData: userData,
                  onNavigate: (index, {bookingStatus}) {
                    setState(() {
                      currentIndex = index;
                      if (bookingStatus != null) {
                        selectedBookingStatus = bookingStatus;
                      }
                    });
                  },
                ),
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
            backgroundColor: AppColors.bgWhite,
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
                  setState(() {
                    currentIndex = index;
                    if (index == 1) {
                      selectedBookingStatus = 'P';
                    }
                  });
                }
              },
              height: 70,
              selectedItemColor: AppColors.primary,
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
      backgroundColor: AppColors.bgWhite,
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
      backgroundColor: AppColors.bgWhite,
      appBar: AppBar(
        backgroundColor: AppColors.bgWhite,
        surfaceTintColor: AppColors.bgWhite,
        title: const Text(""),
        centerTitle: true,
        actions: const [
          LanguageSelectorCard(isInLoginPage: false),
          SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_empty, size: 80, color: AppColors.primary),
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
                  backgroundColor: AppColors.primary,
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

  Widget _buildBlockedState(
    BuildContext context,
    UserModel userData,
    AppLocalizations? locale,
  ) {
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      appBar: AppBar(
        backgroundColor: AppColors.bgWhite,
        surfaceTintColor: AppColors.bgWhite,
        title: const Text(""),
        centerTitle: true,
        actions: const [
          LanguageSelectorCard(isInLoginPage: false),
          SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              Text(
                locale?.accountBlocked ?? "Account Blocked",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                locale?.accountBlockedMessage ??
                    "Your account has been blocked by the admin. Please contact support for more information.",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showSupportOptions(context, locale),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    locale?.contactSupport ?? "Contact Support",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _handleLogout(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    locale?.logout ?? "Logout",
                    style: const TextStyle(
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
    );
  }

  Widget _buildRejectedState(
    BuildContext context,
    UserModel userData,
    AppLocalizations? locale,
  ) {
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      appBar: AppBar(
        backgroundColor: AppColors.bgWhite,
        surfaceTintColor: AppColors.bgWhite,
        title: const Text(""),
        centerTitle: true,
        actions: const [
          LanguageSelectorCard(isInLoginPage: false),
          SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cancel, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              Text(
                locale?.applicationRejected ?? "Application Rejected",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Column(
                  children: [
                    Text(
                      locale?.reasonForRejection ?? "Reason for rejection:",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userData.rejectionReason ??
                          locale?.noReasonProvided ??
                          "No reason provided",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ReuploadDocsPage(workerData: userData),
                      ),
                    );
                    if (updated == true && context.mounted) {
                      context.read<LoginBloc>().add(RefreshUserData());
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    locale?.updateDocuments ?? "Update Documents",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _handleLogout(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                  child: Text(
                    locale?.logout ?? "Logout",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSupportOptions(BuildContext context, AppLocalizations? locale) {
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

  Future<void> _handleLogout(BuildContext context) async {
    await LocalStore.clearUID();
    await LocalStore.clearCachedUserData();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Future<void> _showExitDialog(
    BuildContext context,
    AppLocalizations? locale,
  ) async {
    final shouldExit = await showDialog<bool>(
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

    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }
}
