import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklematch/platform/platform_service.dart';

class DeviceFeaturesWidget extends StatefulWidget {
  const DeviceFeaturesWidget({super.key});

  @override
  State<DeviceFeaturesWidget> createState() => _DeviceFeaturesWidgetState();
}

class _DeviceFeaturesWidgetState extends State<DeviceFeaturesWidget> {
  late PlatformService _platformService;
  bool _isPowerSavingMode = false;
  int _batteryLevel = -1;
  Map<String, dynamic> _deviceInfo = {};
  bool _isShakeDetectionActive = false;
  double _screenBrightness = 1.0;
  bool _keepScreenOn = false;

  @override
  void initState() {
    super.initState();
    _platformService = context.read<PlatformService>();
    _initializePlatformData();
    _setupListeners();
  }

  void _initializePlatformData() async {
    try {
      final powerSaving = await _platformService.isPowerSavingModeEnabled();
      final battery = await _platformService.getBatteryLevel();
      final deviceInfo = await _platformService.getDeviceInfo();
      final brightness = await _platformService.getScreenBrightness();

      setState(() {
        _isPowerSavingMode = powerSaving;
        _batteryLevel = battery;
        _deviceInfo = deviceInfo;
        _screenBrightness = brightness;
      });
    } catch (e) {
      print('Error initializing platform data: $e');
    }
  }

  void _setupListeners() {
    _platformService.powerSavingModeStream.listen((isPowerSaving) {
      setState(() {
        _isPowerSavingMode = isPowerSaving;
      });
    });

    _platformService.batteryLevelStream.listen((batteryLevel) {
      setState(() {
        _batteryLevel = batteryLevel;
      });
    });

    _platformService.deviceShakeStream.listen((shaken) {
      if (shaken) {
        _showSnackBar('Device shaken detected!');
        _platformService.triggerHapticFeedback(type: 'medium');
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Features'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoSection(),
            const SizedBox(height: 20),
            _buildHapticSection(),
            const SizedBox(height: 20),
            _buildShakeSection(),
            const SizedBox(height: 20),
            _buildNotificationSection(),
            const SizedBox(height: 20),
            _buildScreenSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device Information',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            _buildInfoRow('Power Saving Mode', _isPowerSavingMode ? 'Enabled' : 'Disabled'),
            _buildInfoRow('Battery Level', _batteryLevel >= 0 ? '$_batteryLevel%' : 'Unknown'),
            if (_deviceInfo.isNotEmpty) ...[
              _buildInfoRow('Platform', _deviceInfo['platform'] ?? 'Unknown'),
              _buildInfoRow('Version', _deviceInfo['version'] ?? 'Unknown'),
              _buildInfoRow('Model', _deviceInfo['model'] ?? 'Unknown'),
              if (_deviceInfo['manufacturer'] != null)
                _buildInfoRow('Manufacturer', _deviceInfo['manufacturer']),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildHapticSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Haptic Feedback',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0,
              children: [
                ElevatedButton(
                  onPressed: () => _platformService.triggerHapticFeedback(type: 'light'),
                  child: const Text('Light'),
                ),
                ElevatedButton(
                  onPressed: () => _platformService.triggerHapticFeedback(type: 'medium'),
                  child: const Text('Medium'),
                ),
                ElevatedButton(
                  onPressed: () => _platformService.triggerHapticFeedback(type: 'heavy'),
                  child: const Text('Heavy'),
                ),
                ElevatedButton(
                  onPressed: () => _platformService.triggerHapticFeedback(type: 'success'),
                  child: const Text('Success'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShakeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shake Detection',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isShakeDetectionActive
                      ? null
                      : () {
                          _platformService.startShakeDetection();
                          setState(() {
                            _isShakeDetectionActive = true;
                          });
                          _showSnackBar('Shake detection started');
                        },
                  child: const Text('Start Detection'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: !_isShakeDetectionActive
                      ? null
                      : () {
                          _platformService.stopShakeDetection();
                          setState(() {
                            _isShakeDetectionActive = false;
                          });
                          _showSnackBar('Shake detection stopped');
                        },
                  child: const Text('Stop Detection'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Status: ${_isShakeDetectionActive ? 'Active' : 'Inactive'}',
              style: TextStyle(
                color: _isShakeDetectionActive ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Notifications',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _platformService.showSystemNotification(
                  title: 'PickleMatch Device Features',
                  body: 'Device features integration is working!',
                );
                _showSnackBar('Notification sent');
              },
              child: const Text('Send Test Notification'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Screen Controls',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text('Brightness: ${(_screenBrightness * 100).round()}%'),
            Slider(
              value: _screenBrightness,
              onChanged: (value) {
                setState(() {
                  _screenBrightness = value;
                });
                _platformService.setScreenBrightness(value);
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Keep Screen On: '),
                Switch(
                  value: _keepScreenOn,
                  onChanged: (value) {
                    setState(() {
                      _keepScreenOn = value;
                    });
                    _platformService.setKeepScreenOn(value);
                    _showSnackBar(value ? 'Screen will stay on' : 'Screen timeout enabled');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up if needed
    super.dispose();
  }
}