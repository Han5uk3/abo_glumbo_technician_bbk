import 'dart:async';
import 'dart:io';

import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/main.dart';
import 'package:aboglumbo_bbk_panel/services/battery_optimization_service.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

class _AppLifecycleObserver extends WidgetsBindingObserver {
  final BookingTrackerService _service;

  _AppLifecycleObserver(this._service);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _service._onAppEnterBackground();
        break;
      case AppLifecycleState.resumed:
        _service._onAppEnterForeground();
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.hidden:
        _service._onAppEnterBackground();
        break;
    }
  }
}

class BookingTrackerService {
  static final BookingTrackerService _instance =
      BookingTrackerService._internal();
  factory BookingTrackerService() => _instance;
  BookingTrackerService._internal() {
    _initializeTrackingState();
    _initializeBackgroundAppState();
  }

  final ValueNotifier<bool> isTracking = ValueNotifier(false);
  final ValueNotifier<bool> isPaused = ValueNotifier(false);
  StreamSubscription<Position>? _positionStream;
  String? _bookingId;
  Timer? _backgroundLocationTimer;
  bool _isAppInBackground = false;
  _AppLifecycleObserver? _lifecycleObserver;

  String? get currentBookingId => _bookingId;

  bool isTrackingBooking(String bookingId) {
    return (isTracking.value || isPaused.value) && _bookingId == bookingId;
  }

  void _initializeBackgroundAppState() {
    _lifecycleObserver = _AppLifecycleObserver(this);
    WidgetsBinding.instance.addObserver(_lifecycleObserver!);
  }

  void _onAppEnterBackground() {
    _isAppInBackground = true;
    if (isTracking.value && _bookingId != null && !isPaused.value) {
      _startBackgroundLocationTimer();
    }
  }

  void _onAppEnterForeground() {
    _isAppInBackground = false;
    _stopBackgroundLocationTimer();
    if (isTracking.value && _bookingId != null && !isPaused.value) {
      _restoreLocationTracking();
    }
  }

  void _startBackgroundLocationTimer() {
    _stopBackgroundLocationTimer();

    final interval = Platform.isIOS ? 30 : 60;

    _backgroundLocationTimer = Timer.periodic(Duration(seconds: interval), (
      timer,
    ) async {
      if (!isTracking.value || _bookingId == null || isPaused.value) {
        timer.cancel();
        return;
      }
      await _updateLocationInBackground();
    });
  }

  void _stopBackgroundLocationTimer() {
    _backgroundLocationTimer?.cancel();
    _backgroundLocationTimer = null;
  }

  Future<void> _updateLocationInBackground() async {
    try {
      final uid = LocalStore.getUID();
      if (uid == null) return;

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      await AppFirestore.usersCollectionRef.doc(uid).set({
        'liveLocation': {
          'accuracy': position.accuracy,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
          'source': 'background',
        },
      }, SetOptions(merge: true));

      debugPrint(
        'Background location updated: ${position.latitude}, ${position.longitude}',
      );
    } catch (e) {
      debugPrint('Error updating background location: $e');
    }
  }

  Future<void> _initializeTrackingState() async {
    try {
      final activeBookingId = LocalStore.getActiveBookingId();
      if (activeBookingId != null && activeBookingId.isNotEmpty) {
        final bookingDoc = await AppFirestore.bookingsCollectionRef
            .doc(activeBookingId)
            .get();

        if (bookingDoc.exists) {
          final bookingData = bookingDoc.data() as Map<String, dynamic>?;
          final isStarted = bookingData?['isStarted'] ?? false;
          final isStartTracking = bookingData?['isStartTracking'] ?? false;
          final isPausedVal = bookingData?['isTrackingPaused'] ?? false;

          if (isStarted && (isStartTracking || isPausedVal)) {
            _bookingId = activeBookingId;
            if (isPausedVal) {
              isPaused.value = true;
              isTracking.value = false;
            } else {
              isTracking.value = true;
              isPaused.value = false;
              _restoreLocationTracking();
            }
          } else {
            LocalStore.setActiveBookingId('');
          }
        } else {
          LocalStore.setActiveBookingId('');
        }
      }
    } catch (e) {
      LocalStore.setActiveBookingId('');
      isTracking.value = false;
      isPaused.value = false;
    }
  }

  Future<void> _restoreLocationTracking() async {
    if (!isTracking.value || _bookingId == null) return;

    try {
      final uid = LocalStore.getUID();
      if (uid == null) return;

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services disabled, cannot restore tracking');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('Location permission denied, cannot restore tracking');
        return;
      }

      LocationSettings settings = _getLocationSettings();

      if (Platform.isIOS && settings is AppleSettings) {
        if (permission == LocationPermission.always) {
          settings = AppleSettings(
            accuracy: LocationAccuracy.high,
            activityType: ActivityType.otherNavigation,
            distanceFilter: 10,
            pauseLocationUpdatesAutomatically: false,
            showBackgroundLocationIndicator: true,
            allowBackgroundLocationUpdates: true,
          );
        } else {
          settings = AppleSettings(
            accuracy: LocationAccuracy.high,
            activityType: ActivityType.otherNavigation,
            distanceFilter: 10,
            pauseLocationUpdatesAutomatically: false,
            showBackgroundLocationIndicator: false,
            allowBackgroundLocationUpdates: false,
          );
        }
      }

      _positionStream?.cancel();
      _positionStream = Geolocator.getPositionStream(locationSettings: settings)
          .listen(
            (Position position) async {
              await _updateLocationToFirestore(position, uid, 'foreground');
            },
            onError: (error) {
              debugPrint('Location stream error during restore: $error');

              if (Platform.isIOS && error.toString().contains('1')) {
                debugPrint(
                  'iOS location permission error during restore - may need "Always" permission',
                );
              }

              Timer(const Duration(seconds: 5), () {
                if (isTracking.value) {
                  _restoreLocationTracking();
                }
              });
            },
          );

      debugPrint('Location tracking restored successfully');
    } catch (e) {
      debugPrint('Error restoring location tracking: $e');

      if (Platform.isIOS && e.toString().contains('1')) {
        debugPrint('iOS location permission issue during restore');
      }
    }
  }

  Future<void> startWorking({
    required BuildContext context,
    required String bookingId,
    required String uid,
  }) async {
    final docs = await AppFirestore.bookingsCollectionRef
        .where('agent.uid', isEqualTo: uid)
        .where('bookingStatusCode', isEqualTo: 'A')
        .where('isStarted', isEqualTo: true)
        .get();

    if (docs.docs.isNotEmpty) {
      final activeDocs = docs.docs.where((doc) => doc.id != bookingId).toList();
      if (activeDocs.isNotEmpty) {
        final localizations = AppLocalizations.of(context);
        throw Exception(
          localizations?.youHaveAnActiveBookingAlready ??
              'You have an active booking already',
        );
      }
    }

    try {
      await _requestLocationPermissions(context);
    } catch (e) {
      if (Platform.isIOS && e.toString().contains('1')) {
        final localizations = AppLocalizations.of(context);
        throw Exception(
          localizations?.locationPermissionErrorIOS ??
              'Location permission error on iOS. Please go to Settings > Privacy & Security > Location Services > Abo Glumbo Worker and select \'Always\' to enable background tracking.',
        );
      }
      rethrow;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      final localizations = AppLocalizations.of(context);
      throw Exception(
        localizations?.locationServicesDisabledPleaseEnable ??
            'Location services are disabled. Please enable them in settings.',
      );
    }

    LocationPermission currentPermission = await Geolocator.checkPermission();

    await AppFirestore.bookingsCollectionRef.doc(bookingId).update({
      'isStarted': true,
      'isStartTracking': true,
      'isTrackingPaused': false,
      'trackingStartedAt': FieldValue.serverTimestamp(),
      'trackingStoppedAt': null,
    });

    LocalStore.setActiveBookingId(bookingId);
    _bookingId = bookingId;
    isPaused.value = false;

    LocationSettings settings = _getLocationSettings(context: context);

    if (Platform.isIOS && settings is AppleSettings) {
      if (currentPermission == LocationPermission.always) {
        settings = AppleSettings(
          accuracy: LocationAccuracy.high,
          activityType: ActivityType.otherNavigation,
          distanceFilter: 10,
          pauseLocationUpdatesAutomatically: false,
          showBackgroundLocationIndicator: true,
          allowBackgroundLocationUpdates: true,
        );
      } else {
        settings = AppleSettings(
          accuracy: LocationAccuracy.high,
          activityType: ActivityType.otherNavigation,
          distanceFilter: 10,
          pauseLocationUpdatesAutomatically: false,
          showBackgroundLocationIndicator: false,
          allowBackgroundLocationUpdates: false,
        );
      }
    }

    _positionStream = Geolocator.getPositionStream(locationSettings: settings)
        .listen(
          (Position position) async {
            await _updateLocationToFirestore(position, uid, 'foreground');
          },
          onError: (error) {
            if (Platform.isIOS && error.toString().contains('1')) {}

            Timer(const Duration(seconds: 5), () {
              if (isTracking.value) {
                _restoreLocationTracking();
              }
            });
          },
        );

    await _configureBackgroundFetch();

    isTracking.value = true;
  }

  Future<void> _requestLocationPermissions(BuildContext context) async {
    if (LocalStore.isCurrentUserAdmin()) return;
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      final localizations = AppLocalizations.of(context);
      throw Exception(
        localizations?.locationPermissionDeniedPleaseGrant ??
            'Location permission denied. Please grant location permission.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      final localizations = AppLocalizations.of(context);
      throw Exception(
        localizations?.locationPermissionPermanentlyDeniedPleaseEnable ??
            'Location permission permanently denied. Please enable it in settings.',
      );
    }

    if (permission == LocationPermission.whileInUse) {
      if (Platform.isAndroid) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.always) {
          final localizations = AppLocalizations.of(context);
          throw Exception(
            localizations?.backgroundLocationPermissionRequired ??
                'Background location permission is required for tracking.',
          );
        }
      } else if (Platform.isIOS) {
        try {
          permission = await Geolocator.requestPermission();

          if (permission == LocationPermission.whileInUse) {
            debugPrint(
              "iOS: Only 'When In Use' permission granted. Background tracking will be limited.",
            );
          } else if (permission == LocationPermission.always) {
            debugPrint(
              "iOS: 'Always' permission granted. Full background tracking available.",
            );
          }
        } catch (e) {
          debugPrint("iOS: Error requesting always permission: $e");

          if (permission == LocationPermission.whileInUse) {
            debugPrint("iOS: Continuing with 'When In Use' permission only.");
          } else {
            rethrow;
          }
        }
      }
    }

    if (Platform.isAndroid) {
      await _checkBatteryOptimization();
    }
  }

  Future<void> _checkBatteryOptimization() async {
    try {
      bool isOptimizationDisabled =
          await BatteryOptimizationService.isBatteryOptimizationDisabled();
      if (!isOptimizationDisabled) {
        debugPrint(
          'Battery optimization is enabled, may affect background location',
        );
      }
    } catch (e) {
      debugPrint('Error checking battery optimization: $e');
    }
  }

  LocationSettings _getLocationSettings({BuildContext? context}) {
    if (Platform.isAndroid) {
      final localizations = context != null
          ? AppLocalizations.of(context)
          : null;
      final notificationText =
          localizations?.trackingYourLocationForServiceDelivery ??
          "Tracking your location for service delivery";
      final notificationTitle =
          localizations?.aboGlumboLocationTracking ??
          "Abo Glumbo - Location Tracking";

      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 30),
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationText: notificationText,
          notificationTitle: notificationTitle,
          enableWakeLock: true,
        ),
      );
    } else if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.otherNavigation,
        distanceFilter: 10,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: false,
        allowBackgroundLocationUpdates: false,
      );
    } else {
      return const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
    }
  }

  Future<void> _updateLocationToFirestore(
    Position position,
    String uid,
    String source,
  ) async {
    try {
      await AppFirestore.usersCollectionRef.doc(uid).set({
        'liveLocation': {
          'accuracy': position.accuracy,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
          'source': source,
          'speed': position.speed,
          'heading': position.heading,
          'altitude': position.altitude,
        },
      }, SetOptions(merge: true));

      debugPrint(
        'Location updated ($source): ${position.latitude}, ${position.longitude}',
      );
    } catch (e) {
      debugPrint('Error updating location to Firestore: $e');
    }
  }

  Future<void> _configureBackgroundFetch() async {
    try {
      if (Platform.isIOS) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission != LocationPermission.always) {
          debugPrint(
            'iOS: Skipping background fetch - requires Always permission',
          );
          return;
        }
      }

      await BackgroundFetch.configure(
        BackgroundFetchConfig(
          minimumFetchInterval: Platform.isIOS ? 15 : 30,
          stopOnTerminate: false,
          enableHeadless: true,
          startOnBoot: true,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresStorageNotLow: false,
          requiresDeviceIdle: false,
          requiredNetworkType: NetworkType.ANY,
        ),
        (String taskId) async {
          debugPrint('Background fetch triggered: $taskId');
          backgroundFetchHeadlessTask(HeadlessTask(taskId, false));
        },
        (String taskId) async {
          debugPrint('Background fetch timeout: $taskId');
          backgroundFetchHeadlessTask(HeadlessTask(taskId, true));
        },
      );

      await BackgroundFetch.start();
      debugPrint('Background fetch configured and started');
    } catch (e) {
      debugPrint('Error configuring background fetch: $e');

      if (Platform.isIOS && e.toString().contains('1')) {
        debugPrint(
          'iOS background fetch not available - continuing with foreground tracking only',
        );
      }
    }
  }

  Future<void> pauseTracking() async {
    isTracking.value = false;
    isPaused.value = true;

    _positionStream?.cancel();
    _positionStream = null;

    _stopBackgroundLocationTimer();

    if (_bookingId != null) {
      try {
        await AppFirestore.bookingsCollectionRef.doc(_bookingId).update({
          'isStartTracking': false,
          'isTrackingPaused': true,
        });
      } catch (e) {
        debugPrint('Error updating booking status for pause: $e');
      }
    }

    debugPrint('Location tracking paused');
  }

  Future<void> stopTracking() async {
    isTracking.value = false;
    isPaused.value = false;

    _positionStream?.cancel();
    _positionStream = null;

    _stopBackgroundLocationTimer();

    try {
      await BackgroundFetch.stop();
    } catch (e) {
      debugPrint('Error stopping background fetch: $e');
    }

    if (_bookingId != null) {
      try {
        await AppFirestore.bookingsCollectionRef.doc(_bookingId).update({
          'isStarted': false,
          'isStartTracking': false,
          'isTrackingPaused': false,
          'trackingStoppedAt': FieldValue.serverTimestamp(),
          'arrivedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Error updating booking status: $e');
      }
    }

    LocalStore.setActiveBookingId('');
    _bookingId = null;

    debugPrint('Location tracking stopped');
  }

  void dispose() {
    _positionStream?.cancel();
    _stopBackgroundLocationTimer();
    if (_lifecycleObserver != null) {
      WidgetsBinding.instance.removeObserver(_lifecycleObserver!);
    }
    BackgroundFetch.stop();
  }

  Future<void> pauseTrackingWarranty() async {
    isTracking.value = false;
    isPaused.value = true;

    _positionStream?.cancel();
    _positionStream = null;

    _stopBackgroundLocationTimer();

    if (_bookingId != null) {
      try {
        await AppFirestore.bookingsCollectionRef.doc(_bookingId).update({
          'isStartTracking': false,
          'isTrackingPaused': true,
          'warranty.isTracking': false,
        });
      } catch (e) {
        debugPrint('Error updating booking status for pause warranty: $e');
      }
    }

    debugPrint('Location tracking paused for warranty');
  }

  Future<void> stopTrackingWarranty() async {
    isTracking.value = false;
    isPaused.value = false;

    _positionStream?.cancel();
    _positionStream = null;

    _stopBackgroundLocationTimer();

    try {
      await BackgroundFetch.stop();
    } catch (e) {
      debugPrint('Error stopping background fetch: $e');
    }

    if (_bookingId != null) {
      try {
        await AppFirestore.bookingsCollectionRef.doc(_bookingId).update({
          'isStarted': false,
          'isStartTracking': false,
          'isTrackingPaused': false,
          'warranty.trackingStoppedAt': FieldValue.serverTimestamp(),
          'warranty.arrivedAt': FieldValue.serverTimestamp(),
          'warranty.isTracking': false,
        });
      } catch (e) {
        debugPrint('Error updating booking status: $e');
      }
    }

    LocalStore.setActiveBookingId('');
    _bookingId = null;

    debugPrint('Location tracking stopped');
  }

  Future<void> startWorkingWarranty({
    required BuildContext context,
    required String bookingId,
    required String uid,
  }) async {
    final docs = await AppFirestore.bookingsCollectionRef
        .where('agent.uid', isEqualTo: uid)
        .where('bookingStatusCode', isEqualTo: 'A')
        .where('isStarted', isEqualTo: true)
        .get();

    if (docs.docs.isNotEmpty) {
      final activeDocs = docs.docs.where((doc) => doc.id != bookingId).toList();
      if (activeDocs.isNotEmpty) {
        final localizations = AppLocalizations.of(context);
        throw Exception(
          localizations?.youHaveAnActiveBookingAlready ??
              'You have an active booking already',
        );
      }
    }

    try {
      await _requestLocationPermissions(context);
    } catch (e) {
      if (Platform.isIOS && e.toString().contains('1')) {
        final localizations = AppLocalizations.of(context);
        throw Exception(
          localizations?.locationPermissionErrorIOS ??
              'Location permission error on iOS. Please go to Settings > Privacy & Security > Location Services > Abo Glumbo Worker and select \'Always\' to enable background tracking.',
        );
      }
      rethrow;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      final localizations = AppLocalizations.of(context);
      throw Exception(
        localizations?.locationServicesDisabledPleaseEnable ??
            'Location services are disabled. Please enable them in settings.',
      );
    }

    LocationPermission currentPermission = await Geolocator.checkPermission();

    await AppFirestore.bookingsCollectionRef.doc(bookingId).update({
      'isStarted': true,
      'isStartTracking': true,
      'isTrackingPaused': false,
      'warranty.trackingStartedAt': FieldValue.serverTimestamp(),
      'warranty.trackingStoppedAt': null,
      'warranty.isTracking': true,
    });

    LocalStore.setActiveBookingId(bookingId);
    _bookingId = bookingId;
    isPaused.value = false;

    LocationSettings settings = _getLocationSettings(context: context);

    if (Platform.isIOS && settings is AppleSettings) {
      if (currentPermission == LocationPermission.always) {
        settings = AppleSettings(
          accuracy: LocationAccuracy.high,
          activityType: ActivityType.otherNavigation,
          distanceFilter: 10,
          pauseLocationUpdatesAutomatically: false,
          showBackgroundLocationIndicator: true,
          allowBackgroundLocationUpdates: true,
        );
      } else {
        settings = AppleSettings(
          accuracy: LocationAccuracy.high,
          activityType: ActivityType.otherNavigation,
          distanceFilter: 10,
          pauseLocationUpdatesAutomatically: false,
          showBackgroundLocationIndicator: false,
          allowBackgroundLocationUpdates: false,
        );
      }
    }

    _positionStream = Geolocator.getPositionStream(locationSettings: settings)
        .listen(
          (Position position) async {
            await _updateLocationToFirestore(position, uid, 'foreground');
          },
          onError: (error) {
            if (Platform.isIOS && error.toString().contains('1')) {}

            Timer(const Duration(seconds: 5), () {
              if (isTracking.value) {
                _restoreLocationTracking();
              }
            });
          },
        );

    await _configureBackgroundFetch();

    isTracking.value = true;
  }
}
