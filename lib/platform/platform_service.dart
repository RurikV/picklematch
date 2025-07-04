import 'dart:async';
import 'package:flutter/services.dart';

class PlatformService {
  static const MethodChannel _channel = MethodChannel('app.vercel.picklematch/platform');
  
  // Singleton pattern
  static final PlatformService _instance = PlatformService._internal();
  factory PlatformService() => _instance;
  PlatformService._internal();

  // Check if power saving mode is enabled
  Future<bool> isPowerSavingModeEnabled() async {
    try {
      final bool result = await _channel.invokeMethod('isPowerSavingModeEnabled');
      return result;
    } on PlatformException catch (e) {
      print('Failed to get power saving mode: ${e.message}');
      return false;
    }
  }

  // Stream for power saving mode changes
  Stream<bool> get powerSavingModeStream {
    final controller = StreamController<bool>.broadcast();
    
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'powerSavingModeChanged') {
        controller.add(call.arguments as bool);
      }
    });
    
    // Initial value
    isPowerSavingModeEnabled().then((value) {
      controller.add(value);
    });
    
    return controller.stream;
  }
}