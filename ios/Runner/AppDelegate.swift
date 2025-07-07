import Flutter
import UIKit
import CoreMotion
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let CHANNEL = "app.vercel.picklematch/platform"
  private var methodChannel: FlutterMethodChannel?
  private var motionManager: CMMotionManager?
  private var isShakeDetectionActive = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController
    methodChannel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: controller.binaryMessenger)

    methodChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      self?.handleMethodCall(call: call, result: result)
    }

    // Initialize motion manager
    motionManager = CMMotionManager()

    // Request notification permissions
    requestNotificationPermissions()

    // Monitor battery state changes
    UIDevice.current.isBatteryMonitoringEnabled = true
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(batteryStateDidChange),
      name: UIDevice.batteryStateDidChangeNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(batteryLevelDidChange),
      name: UIDevice.batteryLevelDidChangeNotification,
      object: nil
    )

    // Monitor low power mode changes
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(powerStateDidChange),
      name: .NSProcessInfoPowerStateDidChange,
      object: nil
    )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isPowerSavingModeEnabled":
      result(isPowerSavingModeEnabled())
    case "getBatteryLevel":
      result(getBatteryLevel())
    case "getDeviceInfo":
      result(getDeviceInfo())
    case "triggerHapticFeedback":
      let arguments = call.arguments as? [String: Any]
      let type = arguments?["type"] as? String ?? "light"
      triggerHapticFeedback(type: type)
      result(nil)
    case "startShakeDetection":
      startShakeDetection()
      result(nil)
    case "stopShakeDetection":
      stopShakeDetection()
      result(nil)
    case "showSystemNotification":
      let arguments = call.arguments as? [String: Any]
      let title = arguments?["title"] as? String ?? ""
      let body = arguments?["body"] as? String ?? ""
      let channelId = arguments?["channelId"] as? String ?? "picklematch_default"
      showSystemNotification(title: title, body: body, channelId: channelId)
      result(nil)
    case "getScreenBrightness":
      result(getScreenBrightness())
    case "setScreenBrightness":
      let arguments = call.arguments as? [String: Any]
      let brightness = arguments?["brightness"] as? Double ?? 1.0
      setScreenBrightness(brightness: brightness)
      result(nil)
    case "setKeepScreenOn":
      let arguments = call.arguments as? [String: Any]
      let keepOn = arguments?["keepOn"] as? Bool ?? false
      setKeepScreenOn(keepOn: keepOn)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func isPowerSavingModeEnabled() -> Bool {
    return ProcessInfo.processInfo.isLowPowerModeEnabled
  }

  private func getBatteryLevel() -> Int {
    let batteryLevel = UIDevice.current.batteryLevel
    return batteryLevel >= 0 ? Int(batteryLevel * 100) : -1
  }

  private func getDeviceInfo() -> [String: Any] {
    let device = UIDevice.current
    return [
      "platform": "ios",
      "version": device.systemVersion,
      "model": device.model,
      "name": device.name,
      "systemName": device.systemName,
      "identifierForVendor": device.identifierForVendor?.uuidString ?? "unknown"
    ]
  }

  private func triggerHapticFeedback(type: String) {
    switch type {
    case "light":
      let impactFeedback = UIImpactFeedbackGenerator(style: .light)
      impactFeedback.impactOccurred()
    case "medium":
      let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
      impactFeedback.impactOccurred()
    case "heavy":
      let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
      impactFeedback.impactOccurred()
    case "selection":
      let selectionFeedback = UISelectionFeedbackGenerator()
      selectionFeedback.selectionChanged()
    case "success":
      let notificationFeedback = UINotificationFeedbackGenerator()
      notificationFeedback.notificationOccurred(.success)
    case "warning":
      let notificationFeedback = UINotificationFeedbackGenerator()
      notificationFeedback.notificationOccurred(.warning)
    case "error":
      let notificationFeedback = UINotificationFeedbackGenerator()
      notificationFeedback.notificationOccurred(.error)
    default:
      let impactFeedback = UIImpactFeedbackGenerator(style: .light)
      impactFeedback.impactOccurred()
    }
  }

  private func startShakeDetection() {
    guard let motionManager = motionManager, motionManager.isAccelerometerAvailable else {
      return
    }

    if !isShakeDetectionActive {
      motionManager.accelerometerUpdateInterval = 0.1
      motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
        guard let acceleration = data?.acceleration else { return }

        let magnitude = sqrt(acceleration.x * acceleration.x + 
                           acceleration.y * acceleration.y + 
                           acceleration.z * acceleration.z)

        if magnitude > 2.5 { // Shake threshold
          self?.methodChannel?.invokeMethod("deviceShaken", arguments: true)
        }
      }
      isShakeDetectionActive = true
    }
  }

  private func stopShakeDetection() {
    motionManager?.stopAccelerometerUpdates()
    isShakeDetectionActive = false
  }

  private func requestNotificationPermissions() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      if let error = error {
        print("Notification permission error: \(error)")
      }
    }
  }

  private func showSystemNotification(title: String, body: String, channelId: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default

    let request = UNNotificationRequest(
      identifier: UUID().uuidString,
      content: content,
      trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
    )

    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        print("Notification error: \(error)")
      }
    }
  }

  private func getScreenBrightness() -> Double {
    return Double(UIScreen.main.brightness)
  }

  private func setScreenBrightness(brightness: Double) {
    UIScreen.main.brightness = CGFloat(max(0.0, min(1.0, brightness)))
  }

  private func setKeepScreenOn(keepOn: Bool) {
    UIApplication.shared.isIdleTimerDisabled = keepOn
  }

  @objc private func batteryStateDidChange() {
    methodChannel?.invokeMethod("powerSavingModeChanged", arguments: isPowerSavingModeEnabled())
  }

  @objc private func batteryLevelDidChange() {
    methodChannel?.invokeMethod("batteryLevelChanged", arguments: getBatteryLevel())
  }

  @objc private func powerStateDidChange() {
    methodChannel?.invokeMethod("powerSavingModeChanged", arguments: isPowerSavingModeEnabled())
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
    stopShakeDetection()
  }
}
