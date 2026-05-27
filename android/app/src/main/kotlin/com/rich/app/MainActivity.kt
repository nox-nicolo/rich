package com.rich.app

import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private val overlayChannel    = "com.rich.app/overlay"
    private val screenshotChannel = "com.rich.app/screenshot"
    private val widgetChannel     = "com.rich.app/widget"
    private val frequencyChannel  = "com.rich.app/frequency"
    private val requestOverlayCode = 1001

    private var overlayPendingResult: MethodChannel.Result? = null
    private var toneTrack: AudioTrack? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        setupOverlayChannel(flutterEngine)
        setupScreenshotChannel(flutterEngine)
        setupWidgetChannel(flutterEngine)
        setupFrequencyChannel(flutterEngine)
    }

    // ── Overlay Channel ───────────────────────────────────────────────────────

    private fun setupOverlayChannel(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            overlayChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {

                "hasOverlayPermission" ->
                    result.success(canDrawOverlays())

                "requestOverlayPermission" -> {
                    if (canDrawOverlays()) {
                        result.success(true)
                        return@setMethodCallHandler
                    }
                    overlayPendingResult = result
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:$packageName")
                    )
                    startActivityForResult(intent, requestOverlayCode)
                }

                "showOverlay" -> {
                    if (!canDrawOverlays()) {
                        result.error("PERMISSION_DENIED",
                            "SYSTEM_ALERT_WINDOW not granted", null)
                        return@setMethodCallHandler
                    }
                    val svc = Intent(this, OverlayWindowService::class.java)
                    svc.action = OverlayWindowService.ACTION_SHOW
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(svc)
                    } else {
                        startService(svc)
                    }
                    result.success(null)
                }

                "hideOverlay" -> {
                    val svc = Intent(this, OverlayWindowService::class.java)
                    svc.action = OverlayWindowService.ACTION_HIDE
                    startService(svc)
                    result.success(null)
                }

                "updateOverlayPosition" -> {
                    val x = (call.argument<Double>("x") ?: 0.0).toFloat()
                    val y = (call.argument<Double>("y") ?: 0.0).toFloat()
                    val svc = Intent(this, OverlayWindowService::class.java)
                    svc.action = OverlayWindowService.ACTION_MOVE
                    svc.putExtra(OverlayWindowService.EXTRA_X, x)
                    svc.putExtra(OverlayWindowService.EXTRA_Y, y)
                    startService(svc)
                    result.success(null)
                }

                "launchMainApp" -> {
                    val intent = Intent(this, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                                Intent.FLAG_ACTIVITY_SINGLE_TOP
                    }
                    startActivity(intent)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun canDrawOverlays(): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            Settings.canDrawOverlays(this)
        else true

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == requestOverlayCode) {
            overlayPendingResult?.success(canDrawOverlays())
            overlayPendingResult = null
        }
    }

    // ── Screenshot Channel ────────────────────────────────────────────────────

    private fun setupScreenshotChannel(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            screenshotChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "captureScreen" -> result.success(null)
                else            -> result.notImplemented()
            }
        }
    }

    // ── Widget Snapshot Channel ──────────────────────────────────────────────

    private fun setupWidgetChannel(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            widgetChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveSnapshot" -> {
                    val args = call.arguments as? Map<*, *>
                    if (args == null) {
                        result.error("BAD_ARGS", "Expected widget snapshot map", null)
                        return@setMethodCallHandler
                    }

                    val prefs = getSharedPreferences("rich_widget_snapshot", MODE_PRIVATE)
                    val editor = prefs.edit()
                    for ((key, value) in args) {
                        if (key is String) editor.putString(key, value?.toString() ?: "")
                    }
                    editor.apply()
                    RichWidgetUpdater.updateAll(this)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    // ── Meditation Frequency Channel ───────────────────────────────────────

    private fun setupFrequencyChannel(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            frequencyChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "play" -> {
                    val frequencyHz = call.argument<Double>("frequencyHz") ?: 432.0
                    val volume = call.argument<Double>("volume") ?: 0.14
                    playFrequency(frequencyHz, volume)
                    result.success(null)
                }

                "stop" -> {
                    stopFrequency()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun playFrequency(frequencyHz: Double, volume: Double) {
        stopFrequency()

        val sampleRate = 44100
        val seconds = 4
        val sampleCount = sampleRate * seconds
        val amplitude = (Short.MAX_VALUE * volume.coerceIn(0.0, 1.0)).toInt()
        val buffer = ShortArray(sampleCount)

        for (i in buffer.indices) {
            val angle = 2.0 * Math.PI * i * frequencyHz / sampleRate
            buffer[i] = (Math.sin(angle) * amplitude).toInt().toShort()
        }

        val minBufferSize = AudioTrack.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_OUT_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        )
        val bufferBytes = maxOf(minBufferSize, buffer.size * 2)

        val track = AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )
            .setAudioFormat(
                AudioFormat.Builder()
                    .setSampleRate(sampleRate)
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .build()
            )
            .setBufferSizeInBytes(bufferBytes)
            .setTransferMode(AudioTrack.MODE_STATIC)
            .build()

        track.write(buffer, 0, buffer.size)
        track.setLoopPoints(0, buffer.size, -1)
        track.play()
        toneTrack = track
    }

    private fun stopFrequency() {
        toneTrack?.let {
            try {
                it.pause()
                it.flush()
                it.release()
            } catch (_: Exception) {}
        }
        toneTrack = null
    }

    override fun onDestroy() {
        stopFrequency()
        super.onDestroy()
    }
}
