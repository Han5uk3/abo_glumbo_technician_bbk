import 'package:aboglumbo_bbk_panel/helpers/geohash_helper.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';

/// Service for automatically updating technician's current location
/// - Auto-fetches on app startup
/// - Periodically updates in background
/// - Stores location in Firestore
class TechnicianLocationUpdateService {
  static const String _backgroundTaskName = 'technician.location.update';
  static const Duration _backgroundFetchInterval = Duration(minutes: 15);

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize background location updates
  /// Should be called once on app startup
  static Future<void> initializeBackgroundLocationUpdates() async
  {

    try {
      // Configure background fetch
      await BackgroundFetch.configure(
        BackgroundFetchConfig(
          minimumFetchInterval: _backgroundFetchInterval.inMinutes,
          stopOnTerminate: false,
          enableHeadless: true,
          requiresBatteryNotLow: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
          startOnBoot: true,
        ),
        _backgroundFetchHeadlessTask,
        _onBackgroundFetchTimeout,
      );

      debugPrint('✅ Background location update service initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize background location updates: $e');
    }

  }

  /// Callback for background fetch tasks
  static void _backgroundFetchHeadlessTask(String taskId) async {

    try {
      debugPrint('🔄 Running background location update task');
      await _updateTechnicianLocation();
      BackgroundFetch.finish(taskId);
    } catch (e) {
      debugPrint('❌ Background task failed: $e');
      BackgroundFetch.finish(taskId);
    }
  }

  /// Callback for background fetch timeout
  static void _onBackgroundFetchTimeout(String taskId)
  {
    debugPrint('⏱️ Background task timeout: $taskId');
    BackgroundFetch.finish(taskId);
  }

  /// Update technician's current location in Firestore
  /// Call this on app startup and during background tasks
  static Future<void> _updateTechnicianLocation() async {
    try {
      final uid = LocalStore.getUID();
      if (uid == null || uid.isEmpty) {
        debugPrint('⚠️ No user UID found');
        return;
      }

      debugPrint('📍 Starting location update for UID: $uid');

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('⚠️ Location permissions denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Location permissions permanently denied');
        return;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ Location services disabled');
        return;
      }

      // Try to get last known position first for faster update
      Position? position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        debugPrint('📍 Found last known position: ${position.latitude}, ${position.longitude}');
        await _updateFirestoreLocation(uid, position);
      }

      // Then get fresh position
      debugPrint('🛰️ Requesting fresh position...');
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      debugPrint(
        '✅ Got fresh position: ${position.latitude}, ${position.longitude}',
      );

      await _updateFirestoreLocation(uid, position);
    } catch (e) {
      debugPrint('❌ Error updating location: $e');
    }
  }

  static Future<void> _updateFirestoreLocation(String uid, Position position) async {
    Map<String, dynamic> updateData = {
      'liveLocation': {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'heading': position.heading,
        'speed': position.speed,
      },
      'last_known_location': GeoPoint(position.latitude, position.longitude),
      'geohash': GeohashHelper.encode(position.latitude, position.longitude),
      'location.lat': position.latitude,
      'location.lon': position.longitude,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Try to get address details via reverse geocoding
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 5));

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        updateData['location.city'] = place.locality;
        updateData['location.province'] = place.administrativeArea;
        updateData['location.street'] = place.subLocality ?? place.thoroughfare;
        
        final parts = <String>[];
        if (place.subLocality != null && place.subLocality!.isNotEmpty) parts.add(place.subLocality!);
        if (place.locality != null && place.locality!.isNotEmpty) parts.add(place.locality!);
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) parts.add(place.administrativeArea!);
        
        if (parts.isNotEmpty) {
          updateData['location.fullAddress'] = parts.join(', ');
        }
        debugPrint('📍 Address updated: ${updateData['location.fullAddress']}');
      }
    } catch (e) {
      debugPrint('⚠️ Reverse geocoding failed or timed out: $e');
    }

    await _firestore.collection('users').doc(uid).update(updateData);
    debugPrint('✅ Firestore updated for UID: $uid');
  }

  /// Manually trigger location update (call this when app comes to foreground)
  /// If [context] is provided, it will prompt the user if permissions are missing
  static Future<void> updateLocationNow({BuildContext? context}) async {
    try {
      debugPrint('🔄 Manually updating location...');
      if (context != null) {
        await ensureLocationPermissionAndFetch(context);
      } else {
        await _updateTechnicianLocation();
      }
    } catch (e) {
      debugPrint('❌ Failed to update location: $e');
    }
  }

  /// Ensures location permissions are granted and fetches the location
  /// Prompts the user to enable permissions if denied
  static Future<void> ensureLocationPermissionAndFetch(
    BuildContext context,
  ) async {
    final locale = AppLocalizations.of(context);

    // 1. Check if services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        _showPermissionDialog(
          context,
          title: locale?.locationServicesDisabled ?? 'Location Services Disabled',
          message:
              locale?.pleaseEnableLocationServices ??
              'Please enable location services to continue using the app as a technician.',
          onOpenSettings: () => Geolocator.openLocationSettings(),
        );
      }
      return;
    }

    // 2. Check permission
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Still denied
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        _showPermissionDialog(
          context,
          title: locale?.locationPermissionRequired ?? 'Location Permission Required',
          message:
              locale?.locationPermissionPermanentlyDeniedMessage ??
              'Location permissions are permanently denied. Please enable them in app settings to receive job offers.',
          onOpenSettings: () => Geolocator.openAppSettings(),
        );
      }
      return;
    }

    // 3. Permission granted, update location
    await _updateTechnicianLocation();
  }

  static void _showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onOpenSettings,
  }) {
    final locale = AppLocalizations.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.location_off_rounded, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 18))),
          ],
        ),
        content: Text(message, style: GoogleFonts.dmSans(fontSize: 14, color: Colors.grey[700])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale?.later ?? 'Later', style: const TextStyle(color: Colors.grey)),
          ),
          const SizedBox(width: 8),
          eButton(
            context: context,
            text: locale?.openSettings ?? 'Open Settings',
            onPressed: () {
              Navigator.pop(context);
              onOpenSettings();
            },
            backgroundColor: AppColors.primary,
            textColor: Colors.white,
          ),
        ],
      ),
    );
  }

  /// Stop background location updates
  static Future<void> stopBackgroundLocationUpdates() async {
    try {
      await BackgroundFetch.stop();
      debugPrint('✅ Background location updates stopped');
    } catch (e) {
      debugPrint('❌ Failed to stop background updates: $e');
    }
  }

  /// Start background location updates
  static Future<void> startBackgroundLocationUpdates() async {
    try {
      await BackgroundFetch.start();
      debugPrint('✅ Background location updates started');
    } catch (e) {
      debugPrint('❌ Failed to start background updates: $e');
    }
  }
}
