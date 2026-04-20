package com.example.rich

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.TextView
import androidx.core.app.NotificationCompat

class OverlayWindowService : Service() {

    companion object {
        const val ACTION_SHOW = "ACTION_SHOW"
        const val ACTION_HIDE = "ACTION_HIDE"
        const val ACTION_MOVE = "ACTION_MOVE"
        const val EXTRA_X     = "extra_x"
        const val EXTRA_Y     = "extra_y"

        private const val CHANNEL_ID   = "rich_overlay_channel"
        private const val NOTIF_ID     = 9001
    }

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var layoutParams: WindowManager.LayoutParams? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        createNotificationChannel()
        startForeground(NOTIF_ID, buildNotification())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_SHOW -> showOverlay()
            ACTION_HIDE -> {
                hideOverlay()
                stopSelf()
            }
            ACTION_MOVE -> {
                val x = intent.getFloatExtra(EXTRA_X, 0f).toInt()
                val y = intent.getFloatExtra(EXTRA_Y, 0f).toInt()
                moveOverlay(x, y)
            }
        }
        return START_STICKY
    }

    // ── Overlay Window ────────────────────────────────────────────────────────

    private fun showOverlay() {
        if (overlayView != null) return

        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE

        layoutParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 16
            y = 200
        }

        // Simple pill view — label says "RICH"
        val view = LayoutInflater.from(this)
            .inflate(R.layout.overlay_pill, null, false)

        view.setOnTouchListener(DragTouchListener())

        view.findViewById<TextView>(R.id.overlay_label)?.apply {
            text = "RICH"
            setOnClickListener { launchApp() }
        }

        overlayView = view
        windowManager?.addView(view, layoutParams)
    }

    private fun hideOverlay() {
        overlayView?.let {
            windowManager?.removeView(it)
            overlayView = null
        }
    }

    private fun moveOverlay(x: Int, y: Int) {
        val lp = layoutParams ?: return
        val v  = overlayView  ?: return
        lp.x = x
        lp.y = y
        windowManager?.updateViewLayout(v, lp)
    }

    private fun launchApp() {
        val intent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        } ?: return
        startActivity(intent)
    }

    override fun onDestroy() {
        hideOverlay()
        super.onDestroy()
    }

    // ── Draggable touch listener ──────────────────────────────────────────────

    inner class DragTouchListener : View.OnTouchListener {
        private var initialX = 0
        private var initialY = 0
        private var touchX   = 0f
        private var touchY   = 0f

        override fun onTouch(v: View, event: MotionEvent): Boolean {
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = layoutParams?.x ?: 0
                    initialY = layoutParams?.y ?: 0
                    touchX   = event.rawX
                    touchY   = event.rawY
                    return true
                }
                MotionEvent.ACTION_MOVE -> {
                    val lp = layoutParams ?: return false
                    lp.x = initialX + (event.rawX - touchX).toInt()
                    lp.y = initialY + (event.rawY - touchY).toInt()
                    windowManager?.updateViewLayout(v, lp)
                    return true
                }
            }
            return false
        }
    }

    // ── Foreground notification ───────────────────────────────────────────────

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "RICH Overlay",
                NotificationManager.IMPORTANCE_MIN
            ).apply { setShowBadge(false) }
            val mgr = getSystemService(NotificationManager::class.java)
            mgr.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification =
        NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("RICH is active")
            .setContentText("Overlay session running")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setOngoing(true)
            .build()
}
