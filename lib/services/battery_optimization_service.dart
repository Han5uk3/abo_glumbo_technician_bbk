import 'dart:io';
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
    } on PlatformException {
      return false;
    }
  }

  /// Request to disable battery optimization
  static Future<void> requestDisableBatteryOptimization() async {
    if (!Platform.isAndroid) return;

    try {
      await _channel.invokeMethod('requestDisableBatteryOptimization');
    } on PlatformException {
      // Not supported on this device; nothing to request.
    }
  }

  /// Open app settings where user can manually disable battery optimization
  static Future<void> openBatteryOptimizationSettings() async {
    if (!Platform.isAndroid) return;

    try {
      await _channel.invokeMethod('openBatteryOptimizationSettings');
    } on PlatformException {
      // Settings screen not available on this device.
    }
  }
}
