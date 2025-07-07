package app.vercel.picklematch.picklematch

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.BatteryManager
import android.os.Build
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.provider.Settings
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import kotlin.math.sqrt

class MainActivity: FlutterActivity(), SensorEventListener {
    private val CHANNEL = "app.vercel.picklematch/platform"
    private var methodChannel: MethodChannel? = null
    private var powerSavingModeReceiver: BroadcastReceiver? = null
    private var batteryReceiver: BroadcastReceiver? = null
    private var sensorManager: SensorManager? = null
    private var accelerometer: Sensor? = null
    private var isShakeDetectionActive = false
    private var lastShakeTime: Long = 0
    private val shakeThreshold = 12.0f
    private val shakeTimeLapse = 2000

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isPowerSavingModeEnabled" -> {
                    result.success(isPowerSavingModeEnabled())
                }
                "startPowerSavingModeListener" -> {
                    startPowerSavingModeListener()
                    result.success(null)
                }
                "getBatteryLevel" -> {
                    result.success(getBatteryLevel())
                }
                "getDeviceInfo" -> {
                    result.success(getDeviceInfo())
                }
                "triggerHapticFeedback" -> {
                    val type = call.argument<String>("type") ?: "light"
                    triggerHapticFeedback(type)
                    result.success(null)
                }
                "startShakeDetection" -> {
                    startShakeDetection()
                    result.success(null)
                }
                "stopShakeDetection" -> {
                    stopShakeDetection()
                    result.success(null)
                }
                "showSystemNotification" -> {
                    val title = call.argument<String>("title") ?: ""
                    val body = call.argument<String>("body") ?: ""
                    val channelId = call.argument<String>("channelId") ?: "picklematch_default"
                    showSystemNotification(title, body, channelId)
                    result.success(null)
                }
                "getScreenBrightness" -> {
                    result.success(getScreenBrightness())
                }
                "setScreenBrightness" -> {
                    val brightness = call.argument<Double>("brightness") ?: 1.0
                    setScreenBrightness(brightness.toFloat())
                    result.success(null)
                }
                "setKeepScreenOn" -> {
                    val keepOn = call.argument<Boolean>("keepOn") ?: false
                    setKeepScreenOn(keepOn)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Initialize sensors
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        accelerometer = sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

        // Create notification channel
        createNotificationChannel()
    }

    private fun isPowerSavingModeEnabled(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                powerManager.isPowerSaveMode
            } else {
                // For older versions, check battery level and charging state
                val batteryStatus: Intent? = IntentFilter(Intent.ACTION_BATTERY_CHANGED).let { ifilter ->
                    registerReceiver(null, ifilter)
                }

                val status: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
                val isCharging: Boolean = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                        status == BatteryManager.BATTERY_STATUS_FULL

                val level: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
                val scale: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1

                val batteryPct = level * 100 / scale.toFloat()

                // Consider power saving mode enabled if battery is low and not charging
                !isCharging && batteryPct < 15
            }
        } else {
            false
        }
    }

    private fun startPowerSavingModeListener() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            powerSavingModeReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    if (intent?.action == PowerManager.ACTION_POWER_SAVE_MODE_CHANGED) {
                        methodChannel?.invokeMethod("powerSavingModeChanged", isPowerSavingModeEnabled())
                    }
                }
            }

            batteryReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    if (intent?.action == Intent.ACTION_BATTERY_CHANGED) {
                        methodChannel?.invokeMethod("batteryLevelChanged", getBatteryLevel())
                    }
                }
            }

            registerReceiver(powerSavingModeReceiver, IntentFilter(PowerManager.ACTION_POWER_SAVE_MODE_CHANGED))
            registerReceiver(batteryReceiver, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        }
    }

    private fun getBatteryLevel(): Int {
        val batteryStatus: Intent? = IntentFilter(Intent.ACTION_BATTERY_CHANGED).let { ifilter ->
            registerReceiver(null, ifilter)
        }

        val level: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1

        return if (level != -1 && scale != -1) {
            (level * 100 / scale.toFloat()).toInt()
        } else {
            -1
        }
    }

    private fun getDeviceInfo(): Map<String, Any> {
        return mapOf(
            "platform" to "android",
            "version" to Build.VERSION.RELEASE,
            "sdkVersion" to Build.VERSION.SDK_INT,
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            "device" to Build.DEVICE,
            "brand" to Build.BRAND,
            "hardware" to Build.HARDWARE
        )
    }

    private fun triggerHapticFeedback(type: String) {
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as android.os.VibratorManager
            vibratorManager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val effect = when (type) {
                "light" -> VibrationEffect.createOneShot(50, VibrationEffect.DEFAULT_AMPLITUDE)
                "medium" -> VibrationEffect.createOneShot(100, VibrationEffect.DEFAULT_AMPLITUDE)
                "heavy" -> VibrationEffect.createOneShot(200, VibrationEffect.DEFAULT_AMPLITUDE)
                else -> VibrationEffect.createOneShot(50, VibrationEffect.DEFAULT_AMPLITUDE)
            }
            vibrator.vibrate(effect)
        } else {
            @Suppress("DEPRECATION")
            val duration = when (type) {
                "light" -> 50L
                "medium" -> 100L
                "heavy" -> 200L
                else -> 50L
            }
            vibrator.vibrate(duration)
        }
    }

    private fun startShakeDetection() {
        if (!isShakeDetectionActive && accelerometer != null) {
            sensorManager?.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_UI)
            isShakeDetectionActive = true
        }
    }

    private fun stopShakeDetection() {
        if (isShakeDetectionActive) {
            sensorManager?.unregisterListener(this)
            isShakeDetectionActive = false
        }
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event?.sensor?.type == Sensor.TYPE_ACCELEROMETER) {
            val x = event.values[0]
            val y = event.values[1]
            val z = event.values[2]

            val acceleration = sqrt((x * x + y * y + z * z).toDouble()) - SensorManager.GRAVITY_EARTH
            val currentTime = System.currentTimeMillis()

            if (acceleration > shakeThreshold && currentTime - lastShakeTime > shakeTimeLapse) {
                lastShakeTime = currentTime
                methodChannel?.invokeMethod("deviceShaken", true)
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // Not needed for shake detection
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "PickleMatch Notifications"
            val descriptionText = "Notifications from PickleMatch game"
            val importance = NotificationManager.IMPORTANCE_DEFAULT
            val channel = NotificationChannel("picklematch_default", name, importance).apply {
                description = descriptionText
            }
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun showSystemNotification(title: String, body: String, channelId: String) {
        val builder = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)

        with(NotificationManagerCompat.from(this)) {
            notify(System.currentTimeMillis().toInt(), builder.build())
        }
    }

    private fun getScreenBrightness(): Double {
        return try {
            Settings.System.getInt(contentResolver, Settings.System.SCREEN_BRIGHTNESS) / 255.0
        } catch (e: Settings.SettingNotFoundException) {
            1.0
        }
    }

    private fun setScreenBrightness(brightness: Float) {
        val layoutParams = window.attributes
        layoutParams.screenBrightness = brightness.coerceIn(0.0f, 1.0f)
        window.attributes = layoutParams
    }

    private fun setKeepScreenOn(keepOn: Boolean) {
        if (keepOn) {
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        powerSavingModeReceiver?.let { unregisterReceiver(it) }
        batteryReceiver?.let { unregisterReceiver(it) }
        stopShakeDetection()
    }
}
