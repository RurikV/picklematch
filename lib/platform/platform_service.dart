import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

class PlatformService {
  static const MethodChannel _channel = MethodChannel('app.vercel.picklematch/platform');

  // Singleton pattern
  static final PlatformService _instance = PlatformService._internal();
  factory PlatformService() => _instance;
  PlatformService._internal();

  // Initialize platform service and set up listeners
  Future<void> initialize() async {
    _setupMethodCallHandler();
    if (Platform.isAndroid) {
      await _channel.invokeMethod('startPowerSavingModeListener');
    }
  }

  void _setupMethodCallHandler() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'powerSavingModeChanged':
          _powerSavingController.add(call.arguments as bool);
          break;
        case 'batteryLevelChanged':
          _batteryLevelController.add(call.arguments as int);
          break;
        case 'deviceShaken':
          _deviceShakeController.add(true);
          break;
      }
    });
  }

  // Power Saving Mode functionality
  final StreamController<bool> _powerSavingController = StreamController<bool>.broadcast();

  Future<bool> isPowerSavingModeEnabled() async {
    try {
      final bool result = await _channel.invokeMethod('isPowerSavingModeEnabled');
      return result;
    } on PlatformException catch (e) {
      print('Failed to get power saving mode: ${e.message}');
      return false;
    }
  }

  Stream<bool> get powerSavingModeStream => _powerSavingController.stream;

  // Battery Level functionality
  final StreamController<int> _batteryLevelController = StreamController<int>.broadcast();

  Future<int> getBatteryLevel() async {
    try {
      final int result = await _channel.invokeMethod('getBatteryLevel');
      return result;
    } on PlatformException catch (e) {
      print('Failed to get battery level: ${e.message}');
      return -1;
    }
  }

  Stream<int> get batteryLevelStream => _batteryLevelController.stream;

  // Device Information
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('getDeviceInfo');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      print('Failed to get device info: ${e.message}');
      return {};
    }
  }

  // Haptic Feedback
  Future<void> triggerHapticFeedback({String type = 'light'}) async {
    try {
      await _channel.invokeMethod('triggerHapticFeedback', {'type': type});
    } on PlatformException catch (e) {
      print('Failed to trigger haptic feedback: ${e.message}');
    }
  }

  // Device Shake Detection
  final StreamController<bool> _deviceShakeController = StreamController<bool>.broadcast();

  Future<void> startShakeDetection() async {
    try {
      await _channel.invokeMethod('startShakeDetection');
    } on PlatformException catch (e) {
      print('Failed to start shake detection: ${e.message}');
    }
  }

  Future<void> stopShakeDetection() async {
    try {
      await _channel.invokeMethod('stopShakeDetection');
    } on PlatformException catch (e) {
      print('Failed to stop shake detection: ${e.message}');
    }
  }

  Stream<bool> get deviceShakeStream => _deviceShakeController.stream;

  // System Notifications
  Future<void> showSystemNotification({
    required String title,
    required String body,
    String? channelId,
  }) async {
    try {
      await _channel.invokeMethod('showSystemNotification', {
        'title': title,
        'body': body,
        'channelId': channelId ?? 'picklematch_default',
      });
    } on PlatformException catch (e) {
      print('Failed to show system notification: ${e.message}');
    }
  }

  // Screen Brightness Control
  Future<double> getScreenBrightness() async {
    try {
      final double result = await _channel.invokeMethod('getScreenBrightness');
      return result;
    } on PlatformException catch (e) {
      print('Failed to get screen brightness: ${e.message}');
      return 1.0;
    }
  }

  Future<void> setScreenBrightness(double brightness) async {
    try {
      await _channel.invokeMethod('setScreenBrightness', {'brightness': brightness});
    } on PlatformException catch (e) {
      print('Failed to set screen brightness: ${e.message}');
    }
  }

  // Keep Screen On
  Future<void> setKeepScreenOn(bool keepOn) async {
    try {
      await _channel.invokeMethod('setKeepScreenOn', {'keepOn': keepOn});
    } on PlatformException catch (e) {
      print('Failed to set keep screen on: ${e.message}');
    }
  }

  // Cleanup
  void dispose() {
    _powerSavingController.close();
    _batteryLevelController.close();
    _deviceShakeController.close();
  }
}
