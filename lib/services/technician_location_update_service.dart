import 'package:aboglumbo_bbk_panel/helpers/geohash_helper.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:flutter/foundation.dart';

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

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );

      debugPrint(
        '✅ Got position: ${position.latitude}, ${position.longitude}',
      );

      // Reverse geocode to get place name
      String? placeName;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final parts = <String>[];

          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            parts.add(place.subLocality!);
          }
          if (place.locality != null && place.locality!.isNotEmpty) {
            parts.add(place.locality!);
          }
          if (place.administrativeArea != null &&
              place.administrativeArea!.isNotEmpty) {
            parts.add(place.administrativeArea!);
          }

          placeName = parts.join(', ');
          debugPrint('📍 Place name: $placeName');
        }
      } catch (e) {
        debugPrint('⚠️ Reverse geocoding failed: $e');
      }

      // Get formatted place name


      // Update user document with live location and last known location
      await _firestore.collection('users').doc(uid).update({
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
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Location updated in Firestore');
    } catch (e) {
      debugPrint('❌ Error updating location: $e');
    }
  }

  /// Manually trigger location update (call this when app comes to foreground)
  static Future<void> updateLocationNow() async {
    try {
      debugPrint('🔄 Manually updating location...');
      await _updateTechnicianLocation();
    } catch (e) {
      debugPrint('❌ Failed to update location: $e');
    }
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
