
import 'package:google_fonts/google_fonts.dart';
import 'package:aboglumbo_bbk_panel/firebase_options.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/helpers/secure_box.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/pages/account/bloc/account_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/splash.dart';
import 'package:aboglumbo_bbk_panel/providers.dart';
import 'package:aboglumbo_bbk_panel/services/notification_services.dart';

import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'package:aboglumbo_bbk_panel/services/time_service.dart';

// Enhanced Background Fetch Handler
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool timeout = task.timeout;

  if (timeout) {
    BackgroundFetch.finish(taskId);
    return;
  }

  try {
    if (LocalStore.isCurrentUserAdmin()) {
      BackgroundFetch.finish(taskId);
      return;
    }

    final String? bookingId = LocalStore.getActiveBookingId();
    final String? uid = LocalStore.getUID();

    if (bookingId == null || bookingId.isEmpty || uid == null) {
      BackgroundFetch.finish(taskId);
      return;
    }

    // Check if location services are available
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      BackgroundFetch.finish(taskId);
      return;
    }

    // Check permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      BackgroundFetch.finish(taskId);
      return;
    }

    // Get current position with timeout
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 15),
    );

    // Update location in Firestore
    await AppFirestore.usersCollectionRef.doc(uid).set({
      'liveLocation': {
        'accuracy': position.accuracy,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'source': 'background_fetch',
        'taskId': taskId,
      },
    }, SetOptions(merge: true));

  } catch (_) {
  } finally {
    BackgroundFetch.finish(taskId);
  }
}

GlobalKey<NavigatorState>? navigatorKey = GlobalKey();

/// Proves requests come from the genuine app. Never awaited: startup must not
/// depend on the attestation services responding.
Future<void> _activateAppCheck() async {
  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
  } catch (_) {
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Release builds print nothing, including debugPrint calls made inside
  // plugins, so no tokens, phone numbers or IDs end up in device logs.
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // Outside the try below this could abort main() before runApp() and leave the
  // user on a permanently blank screen, so it gets its own guard.
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
  }

  try {
    // STEP 1: Initialize Firebase FIRST
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    _activateAppCheck();

    // STEP 2: Set Database Persistence IMMEDIATELY after Firebase init
    // This must be done BEFORE any other Firebase Database usage
    try {
      FirebaseDatabase.instance.setPersistenceEnabled(true);
      FirebaseDatabase.instance.setPersistenceCacheSizeBytes(
        10000000,
      ); // 10MB cache
    } catch (e) {
      // This is not critical - continue without persistence or it's already enabled
    }

    // STEP 3: Open the encrypted local store (recovers from a corrupt or
    // unreadable box by starting empty, which costs a re-login, not the app).
    await Hive.initFlutter();
    await SecureBox.open();

    // STEP 4: Setup FCM Background Handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // STEP 5: Kick off clock sync WITHOUT awaiting it.
    // Awaiting this is what blanked the app on networks that drop UDP/123: the
    // NTP future never completed, so runApp() below was never reached. Until it
    // lands, TimeService.now falls back to the device clock.
    TimeService.syncInBackground();

    // STEP 6: Setup System UI (with One UI 8 fix)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    // STEP 7: Configure Background Fetch
    try {
      BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);

      await BackgroundFetch.configure(
        BackgroundFetchConfig(
          minimumFetchInterval: Platform.isIOS ? 15 : 30,
          stopOnTerminate: false,
          enableHeadless: true,
          startOnBoot: true,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresStorageNotLow: false,
          requiredNetworkType: NetworkType.ANY,
        ),
        (String taskId) async {
          backgroundFetchHeadlessTask(HeadlessTask(taskId, false));
        },
        (String taskId) async {
          backgroundFetchHeadlessTask(HeadlessTask(taskId, true));
        },
      ).timeout(const Duration(seconds: 10));

    } catch (_) {
    }

  } catch (_) {
  }

  runApp(MyApp(navigatorKey: navigatorKey));
}

class MyApp extends StatelessWidget {
  static Box box = Hive.box(SecureBox.boxName);
  final GlobalKey<NavigatorState>? navigatorKey;
  const MyApp({super.key, this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQueryData.fromView(
      View.of(context),
    ).padding.bottom;
    final bool isThickNavBar = bottomPadding >= 24.0;
    return BlocProvider(
      create: (context) => AccountBloc(),
      child: BlocBuilder<AccountBloc, AccountState>(
        builder: (context, state) {
          return MultiBlocProvider(
            providers: providers,
            child: SafeArea(
              top: false,
              bottom: Platform.isAndroid ? isThickNavBar : false,
              child: MaterialApp(
                key: ValueKey(state.locale.languageCode),
                navigatorKey: navigatorKey,
                title: 'Aboglumbo Technician',
                debugShowCheckedModeBanner: false,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                locale: state.locale,
                supportedLocales: AppLocalizations.supportedLocales,
                theme: ThemeData(
                  fontFamily: state.locale.languageCode == 'ar'
                      ? GoogleFonts.notoKufiArabic().fontFamily
                      : 'DMSans',
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: AppColors.primary,
                  ),
                  scaffoldBackgroundColor: AppColors.bgWhite,
                  navigationBarTheme: NavigationBarThemeData(
                    backgroundColor: Colors.white,
                    indicatorColor: Colors.transparent,
                    labelTextStyle: WidgetStateTextStyle.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return TextStyle(
                          color: AppColors.darkGrey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        );
                      }
                      return TextStyle(color: AppColors.grey, fontSize: 10);
                    }),
                  ),
                  dialogTheme: DialogThemeData(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  filledButtonTheme: FilledButtonThemeData(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  appBarTheme: AppBarTheme(
                    centerTitle: true,
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    iconTheme: const IconThemeData(
                      color: Colors.black,
                      size: 20,
                    ),
                    titleSpacing: 0,
                    titleTextStyle: TextStyle(
                      fontFamily: state.locale.languageCode == 'ar'
                          ? GoogleFonts.notoKufiArabic().fontFamily
                          : 'DMSans',
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  searchBarTheme: SearchBarThemeData(
                    elevation: const WidgetStatePropertyAll(0),
                    backgroundColor: const WidgetStatePropertyAll(Colors.white),
                    textStyle: WidgetStatePropertyAll(
                      TextStyle(color: Colors.black45, fontSize: 14),
                    ),
                    constraints: const BoxConstraints(
                      minHeight: 50,
                      maxHeight: 50,
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    side: const WidgetStatePropertyAll(
                      BorderSide(color: Colors.black12, width: 1),
                    ),
                  ),
                  bottomSheetTheme: const BottomSheetThemeData(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                  ),
                  useMaterial3: true,
                ),
                home: SplashScreen(),
              ),
            ),
          );
        },
      ),
    );
  }
}
