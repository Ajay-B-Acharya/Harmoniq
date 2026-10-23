import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service to manage Android battery optimizations, background power usage access,
/// and wake/wifi locks to prevent the OS from killing playback when the screen is locked
/// or the app is put in the background.
class PowerManagerService {
  PowerManagerService._();
  static final PowerManagerService instance = PowerManagerService._();

  static const MethodChannel _channel =
      MethodChannel('com.example.harmoniq/local_music');

  bool _wakeLockHeld = false;

  /// Checks whether Harmoniq is exempt from battery optimizations (Unrestricted background usage).
  Future<bool> isIgnoringBatteryOptimizations() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final result =
          await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return result ?? false;
    } catch (e) {
      debugPrint('[POWER_MANAGER] Error checking battery optimizations: $e');
      return true;
    }
  }

  /// Requests the user to allow unrestricted background battery usage via the system dialog.
  Future<bool> requestIgnoreBatteryOptimizations() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final result =
          await _channel.invokeMethod<bool>('requestIgnoreBatteryOptimizations');
      return result ?? false;
    } catch (e) {
      debugPrint('[POWER_MANAGER] Error requesting ignore battery optimizations: $e');
      return false;
    }
  }

  /// Opens the device battery optimization settings page as a fallback.
  Future<void> openBatteryOptimizationSettings() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openBatteryOptimizationSettings');
    } catch (e) {
      debugPrint('[POWER_MANAGER] Error opening battery optimization settings: $e');
    }
  }

  /// Acquires a partial wake lock and high-performance wifi lock so that
  /// background streaming & playback do not stall when the screen locks.
  Future<void> acquirePlaybackWakeLock() async {
    if (kIsWeb || !Platform.isAndroid || _wakeLockHeld) return;
    try {
      await _channel.invokeMethod('acquirePlaybackWakeLock');
      _wakeLockHeld = true;
    } catch (e) {
      debugPrint('[POWER_MANAGER] Error acquiring playback wake lock: $e');
    }
  }

  /// Releases the partial wake lock and wifi lock when playback is stopped/paused.
  Future<void> releasePlaybackWakeLock() async {
    if (kIsWeb || !Platform.isAndroid || !_wakeLockHeld) return;
    try {
      await _channel.invokeMethod('releasePlaybackWakeLock');
      _wakeLockHeld = false;
    } catch (e) {
      debugPrint('[POWER_MANAGER] Error releasing playback wake lock: $e');
    }
  }
}
