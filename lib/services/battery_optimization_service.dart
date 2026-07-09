import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BatteryOptimizationService {
  static const MethodChannel _channel = MethodChannel('battery_optimization');

  /// Check if battery optimization is disabled for the app
  static Future<bool> isBatteryOptimizationDisabled() async {
    if (!Platform.isAndroid) return true;

    try {
      final bool isDisabled = await _channel.invokeMethod(
        'isBatteryOptimizationDisabled',
      );
      return isDisabled;
    } on PlatformException catch (e) {
      debugPrint('Error checking battery optimization: $e');
      return false;
    }
  }

  /// Request to disable battery optimization
  static Future<void> requestDisableBatteryOptimization() async {
    if (!Platform.isAndroid) return;

    try {
      await _channel.invokeMethod('requestDisableBatteryOptimization');
    } on PlatformException catch (e) {
      debugPrint('Error requesting battery optimization disable: $e');
    }
  }

  /// Open app settings where user can manually disable battery optimization
  static Future<void> openBatteryOptimizationSettings() async {
    if (!Platform.isAndroid) return;

    try {
      await _channel.invokeMethod('openBatteryOptimizationSettings');
    } on PlatformException catch (e) {
      debugPrint('Error opening battery optimization settings: $e');
    }
  }
}
