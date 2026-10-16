package com.ghostgirl.companion.overlay

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.content.res.Configuration
import android.graphics.PixelFormat
import android.graphics.Rect
import android.graphics.drawable.Icon
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.hardware.display.DisplayManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import android.Manifest
import android.content.pm.PackageManager
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.MotionEvent
import android.view.ViewConfiguration
import android.view.WindowInsets
import android.view.WindowManager
import android.widget.Toast
import androidx.core.net.toUri
import androidx.core.content.ContextCompat
import com.ghostgirl.companion.CaptureConsentActivity
import com.ghostgirl.companion.MainActivity
import com.ghostgirl.companion.R
import com.ghostgirl.companion.capture.ScreenCaptureService
import com.ghostgirl.companion.model.GestureAction
import com.ghostgirl.companion.model.GhostMood
import com.ghostgirl.companion.model.TapSequence
import com.ghostgirl.companion.model.GhostSettingsStore
import com.ghostgirl.companion.model.OverlayGeometry
import com.ghostgirl.companion.model.OverlayPoint
import kotlin.math.abs

/** A user-started, visible foreground service that owns one transparent overlay window. */
class GhostOverlayService : Service(), DisplayManager.DisplayListener {
    private lateinit var overlayContext: Context
    private lateinit var windowManager: WindowManager
    private lateinit var displayManager: DisplayManager
    private lateinit var store: GhostSettingsStore
    private var sprite: GhostSpriteView? = null
    private var windowParams: WindowManager.LayoutParams? = null
    private var initialized = false
    private var foregroundStarted = false
    private var preferencesRegistered = false
    private var displayRegistered = false
    private var receiverRegistered = false
    private val mainHandler = Handler(Looper.getMainLooper())
    private var longPressTask: Runnable? = null
    private val taps = TapSequence()
    private val finishTaps = Runnable {
        taps.flush(SystemClock.uptimeMillis())?.let(::performTapGesture)
    }
    private var downRawX = 0f
    private var downRawY = 0f
    private var startWindowX = 0
    private var startWindowY = 0
    private var dragging = false
    private var longPressed = false
    private var torchOn = false
    private var torchCameraId: String? = null
    private val touchSlop by lazy { ViewConfiguration.get(this).scaledTouchSlop }

    private val preferenceListener = android.content.SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
        if (key in setOf("size_dp", "opacity", "animation_speed", "snap_to_edge", "character_id")) applySettings()
    }

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            sprite?.setScreenActive(intent?.action == Intent.ACTION_SCREEN_ON)
        }
    }

    override fun onCreate() {
        super.onCreate()
        store = GhostSettingsStore(this)
        try {
            createNotificationChannel()
            val notification = buildNotification()
            if (Build.VERSION.SDK_INT >= 34) {
                startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
            foregroundStarted = true
            // A service WindowManager uses the same context as the sprite view and avoids
            // vendor-specific window-token mismatches when attaching an overlay.
            overlayContext = this
            windowManager = overlayContext.getSystemService(WindowManager::class.java)
            displayManager = getSystemService(DisplayManager::class.java)
            store.preferences.registerOnSharedPreferenceChangeListener(preferenceListener)
            preferencesRegistered = true
            displayManager.registerDisplayListener(this, mainHandler)
            displayRegistered = true
            val screenFilter = IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_OFF)
                addAction(Intent.ACTION_SCREEN_ON)
            }
            if (Build.VERSION.SDK_INT >= 33) {
                registerReceiver(screenReceiver, screenFilter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                registerReceiver(screenReceiver, screenFilter)
            }
            receiverRegistered = true
            initialized = true
        } catch (error: RuntimeException) {
            reportFailure("Không khởi tạo được dịch vụ nổi", error)
            stopSelf()
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (!initialized) {
            stopSelf()
            return START_NOT_STICKY
        }
        try {
            when (intent?.action) {
                ACTION_STOP -> stopSelf()
                ACTION_PREVIEW -> sprite?.showMood(
                    GhostMood.fromName(intent.getStringExtra(EXTRA_MOOD)), 2_500L)
                ACTION_TORCH -> toggleTorch()
                ACTION_UPDATE -> applySettings()
                else -> showOverlay()
            }
        } catch (error: RuntimeException) {
            reportFailure("Lỗi khi cập nhật nhân vật nổi", error)
            stopSelf()
        }
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        longPressTask?.let { sprite?.removeCallbacks(it) }
        mainHandler.removeCallbacks(finishTaps)
        taps.cancel()
        if (torchOn) {
            try { torchCameraId?.let { getSystemService(CameraManager::class.java).setTorchMode(it, false) } }
            catch (_: Exception) { /* Camera may be gone during shutdown. */ }
        }
        if (preferencesRegistered) store.preferences.unregisterOnSharedPreferenceChangeListener(preferenceListener)
        if (displayRegistered) displayManager.unregisterDisplayListener(this)
        if (receiverRegistered) unregisterReceiver(screenReceiver)
        removeOverlay()
        if (foregroundStarted) stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        scheduleScreenRefresh()
    }

    override fun onDisplayChanged(displayId: Int) { scheduleScreenRefresh() }
    override fun onDisplayAdded(displayId: Int) { scheduleScreenRefresh() }
    override fun onDisplayRemoved(displayId: Int) { scheduleScreenRefresh() }

    private fun scheduleScreenRefresh() {
        mainHandler.post {
            try {
                refreshScreenBounds()
            } catch (error: RuntimeException) {
                reportFailure("Lỗi khi đổi màn hình", error)
                stopSelf()
            }
        }
    }

    private fun showOverlay() {
        if (!Settings.canDrawOverlays(this)) {
            store.setOverlayError("Android chưa cấp quyền hiển thị trên ứng dụng khác. Hãy cấp quyền rồi thử lại.")
            stopSelf()
            return
        }
        if (sprite != null) {
            applySettings()
            return
        }
        try {
            attachOverlay()
        } catch (error: RuntimeException) {
            reportFailure("Không tạo được cửa sổ nổi", error)
            stopSelf()
        }
    }

    private fun attachOverlay() {
        val settings = store.read()
        val screen = screenInfo()
        val size = sizeForScreen(screen, settings.sizeDp)
        val saved = store.position() ?: OverlayPoint(
            screen.bounds.width() - screen.right - size,
            (screen.bounds.height() - size) / 2,
        )
        val point = OverlayGeometry.clamp(saved, screen.bounds.width(), screen.bounds.height(), size,
            screen.left, screen.top, screen.right, screen.bottom)
        val params = WindowManager.LayoutParams(
            size,
            size,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = point.x
            y = point.y
            alpha = settings.opacity
            title = "GhostGirl floating companion"
        }
        val view = GhostSpriteView(overlayContext).apply {
            contentDescription = "GhostGirl. Chạm một lần mở ChatGPT, hai lần vui vẻ, ba lần đổi nhân vật, giữ để mở cài đặt."
            isClickable = true
            isLongClickable = true
            importantForAccessibility = android.view.View.IMPORTANT_FOR_ACCESSIBILITY_YES
            setAnimationSpeed(settings.animationSpeed)
            setCharacter(settings.character)
            onClicked = { recordTap() }
            onLongPressed = {
                clearTaps()
                showMood(GhostMood.REACTING, 900L)
                openSettings()
            }
            setOnTouchListener { touchedView, event ->
                val handled = handleTouch(event)
                if (event.actionMasked == MotionEvent.ACTION_UP && !dragging && !longPressed) {
                    touchedView.performClick()
                }
                handled
            }
        }
        windowManager.addView(view, params)
        sprite = view
        windowParams = params
        isOverlayVisible = true
        store.savePosition(point)
        store.setOverlayError(null)
        store.setOverlayVisible(true)
    }

    private fun reportFailure(stage: String, error: RuntimeException) {
        Log.e(TAG, stage, error)
        isOverlayVisible = false
        store.setOverlayVisible(false)
        store.setOverlayError("$stage (${error.javaClass.simpleName}): ${error.message.orEmpty().take(180)}")
    }

    private fun applySettings() {
        val params = windowParams ?: return
        val settings = store.read()
        params.alpha = settings.opacity
        sprite?.setAnimationSpeed(settings.animationSpeed)
        sprite?.setCharacter(settings.character)
        refreshScreenBounds()
    }

    private fun refreshScreenBounds() {
        val params = windowParams ?: return
        val screen = screenInfo()
        val size = sizeForScreen(screen, store.read().sizeDp)
        params.width = size
        params.height = size
        val point = OverlayGeometry.clamp(OverlayPoint(params.x, params.y),
            screen.bounds.width(), screen.bounds.height(), params.width,
            screen.left, screen.top, screen.right, screen.bottom)
        params.x = point.x
        params.y = point.y
        updateWindow()
        store.savePosition(point)
    }

    private fun handleTouch(event: MotionEvent): Boolean {
        val params = windowParams ?: return false
        val view = sprite ?: return false
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                downRawX = event.rawX
                downRawY = event.rawY
                startWindowX = params.x
                startWindowY = params.y
                dragging = false
                longPressed = false
                val task = Runnable {
                    if (!dragging) {
                        longPressed = true
                        view.performLongClick()
                    }
                }
                longPressTask = task
                view.postDelayed(task, ViewConfiguration.getLongPressTimeout().toLong())
                return true
            }
            MotionEvent.ACTION_MOVE -> {
                if (longPressed) return true
                val dx = event.rawX - downRawX
                val dy = event.rawY - downRawY
                if (!dragging && (abs(dx) > touchSlop || abs(dy) > touchSlop)) {
                    dragging = true
                    clearTaps()
                    longPressTask?.let(view::removeCallbacks)
                    view.showMood(GhostMood.WALKING)
                }
                if (dragging) {
                    val screen = screenInfo()
                    val point = OverlayGeometry.clamp(
                        OverlayPoint(startWindowX + dx.toInt(), startWindowY + dy.toInt()),
                        screen.bounds.width(), screen.bounds.height(), params.width,
                        screen.left, screen.top, screen.right, screen.bottom,
                    )
                    params.x = point.x
                    params.y = point.y
                    updateWindow()
                }
                return true
            }
            MotionEvent.ACTION_UP -> {
                longPressTask?.let(view::removeCallbacks)
                if (dragging) {
                    finishDrag()
                    view.showMood(GhostMood.IDLE)
                }
                return true
            }
            MotionEvent.ACTION_CANCEL -> {
                longPressTask?.let(view::removeCallbacks)
                if (dragging) finishDrag()
                view.showMood(GhostMood.IDLE)
                return true
            }
        }
        return true
    }

    private fun finishDrag() {
        val params = windowParams ?: return
        val screen = screenInfo()
        val point = if (store.read().snapToEdge) {
            OverlayGeometry.snapToNearestEdge(OverlayPoint(params.x, params.y),
                screen.bounds.width(), screen.bounds.height(), params.width,
                screen.left, screen.top, screen.right, screen.bottom)
        } else {
            OverlayGeometry.clamp(OverlayPoint(params.x, params.y),
                screen.bounds.width(), screen.bounds.height(), params.width,
                screen.left, screen.top, screen.right, screen.bottom)
        }
        params.x = point.x
        params.y = point.y
        updateWindow()
        store.savePosition(point)
    }

    private fun updateWindow() {
        val view = sprite ?: return
        val params = windowParams ?: return
        try {
            windowManager.updateViewLayout(view, params)
        } catch (_: IllegalArgumentException) {
            // A display transition can invalidate the old window before the next callback.
        } catch (error: SecurityException) {
            reportFailure("Android từ chối cập nhật cửa sổ nổi", error)
            stopSelf()
        }
    }

    private fun openSettings() {
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra(MainActivity.EXTRA_OPENED_FROM_OVERLAY, true)
        }
        startActivity(intent)
    }

    private fun recordTap() {
        val gesture = taps.tap(SystemClock.uptimeMillis())
        mainHandler.removeCallbacks(finishTaps)
        gesture?.let(::performTapGesture)
        if (taps.hasPending()) mainHandler.postDelayed(finishTaps, 330L)
    }

    private fun clearTaps() {
        mainHandler.removeCallbacks(finishTaps)
        taps.cancel()
    }

    private fun performTapGesture(gesture: TapSequence.Gesture) {
        when (gesture) {
            TapSequence.Gesture.SINGLE -> {
                sprite?.showMood(GhostMood.HAPPY, 900L)
                launchChatGpt()
            }
            TapSequence.Gesture.DOUBLE -> performConfiguredAction(store.read().doubleTapAction)
            TapSequence.Gesture.TRIPLE -> performConfiguredAction(store.read().tripleTapAction)
        }
    }

    private fun performConfiguredAction(action: GestureAction) {
        when (action) {
            GestureAction.HAPPY -> sprite?.showMood(GhostMood.HAPPY, 2_000L)
            GestureAction.NEXT_CHARACTER -> {
                val next = store.read().character.next()
                sprite?.setCharacter(next)
                store.save(store.read().copy(character = next))
                sprite?.showMood(GhostMood.REACTING, 1_100L)
                Toast.makeText(this, next.label, Toast.LENGTH_SHORT).show()
            }
            GestureAction.OPEN_APP -> launchSelectedApp()
            GestureAction.FLASHLIGHT -> {
                if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
                    toggleTorch()
                } else {
                    startActivity(Intent(this, MainActivity::class.java).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                        putExtra(MainActivity.EXTRA_REQUEST_TORCH, true)
                    })
                }
            }
            GestureAction.SCREENSHOT, GestureAction.SCREEN_RECORD -> {
                if (action == GestureAction.SCREEN_RECORD && ScreenCaptureService.isRecording) {
                    startService(Intent(this, ScreenCaptureService::class.java)
                        .setAction(ScreenCaptureService.ACTION_STOP))
                } else {
                    startActivity(Intent(this, CaptureConsentActivity::class.java).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        putExtra(CaptureConsentActivity.EXTRA_RECORD,
                            action == GestureAction.SCREEN_RECORD)
                    })
                }
            }
        }
    }

    private fun launchSelectedApp() {
        val selected = ComponentName.unflattenFromString(store.read().openAppComponent.orEmpty())
        if (selected == null) {
            launchChatGpt()
            return
        }
        try {
            startActivity(Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
                .setComponent(selected).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        } catch (_: RuntimeException) {
            Toast.makeText(this, "Không mở được ứng dụng đã chọn. Hãy chọn lại trong cài đặt.",
                Toast.LENGTH_LONG).show()
        }
    }

    private fun toggleTorch() {
        try {
            val cameraManager = getSystemService(CameraManager::class.java)
            val cameraId = torchCameraId ?: cameraManager.cameraIdList.firstOrNull { id ->
                val characteristics = cameraManager.getCameraCharacteristics(id)
                characteristics.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true &&
                    characteristics.get(CameraCharacteristics.LENS_FACING) == CameraCharacteristics.LENS_FACING_BACK
            } ?: cameraManager.cameraIdList.firstOrNull { id ->
                cameraManager.getCameraCharacteristics(id)
                    .get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
            }
            if (cameraId == null) {
                Toast.makeText(this, "Thiết bị không có đèn pin", Toast.LENGTH_SHORT).show()
                return
            }
            cameraManager.setTorchMode(cameraId, !torchOn)
            torchCameraId = cameraId
            torchOn = !torchOn
            Toast.makeText(this, if (torchOn) "Đèn pin bật" else "Đèn pin tắt", Toast.LENGTH_SHORT).show()
        } catch (_: Exception) {
            Toast.makeText(this, "Không điều khiển được đèn pin lúc này", Toast.LENGTH_SHORT).show()
        }
    }

    private fun launchChatGpt() {
        val launcher = packageManager.getLaunchIntentForPackage(CHATGPT_PACKAGE)
        if (launcher != null) {
            try {
                launcher.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(launcher)
                return
            } catch (_: android.content.ActivityNotFoundException) {
                // Fall through to the official store listing.
            } catch (_: SecurityException) {
                // The launcher may be unavailable in a restricted profile.
            }
        }
        val market = Intent(Intent.ACTION_VIEW, "market://details?id=$CHATGPT_PACKAGE".toUri())
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            startActivity(market)
        } catch (_: android.content.ActivityNotFoundException) {
            try {
                startActivity(Intent(Intent.ACTION_VIEW,
                    "https://play.google.com/store/apps/details?id=$CHATGPT_PACKAGE".toUri())
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            } catch (_: android.content.ActivityNotFoundException) {
                Toast.makeText(this, "Không tìm thấy ứng dụng để mở Play Store", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun removeOverlay() {
        val view = sprite
        if (view != null && ::windowManager.isInitialized) {
            try {
                windowManager.removeView(view)
            } catch (_: IllegalArgumentException) {
                // Already removed by the window manager during a display change.
            }
        }
        sprite = null
        windowParams = null
        isOverlayVisible = false
        if (::store.isInitialized) store.setOverlayVisible(false)
    }

    private data class ScreenInfo(
        val bounds: Rect,
        val left: Int,
        val top: Int,
        val right: Int,
        val bottom: Int,
    )

    private fun screenInfo(): ScreenInfo {
        return try {
            val metrics = windowManager.currentWindowMetrics
            val safe = metrics.windowInsets.getInsetsIgnoringVisibility(
                WindowInsets.Type.systemBars() or WindowInsets.Type.displayCutout())
            ScreenInfo(metrics.bounds, safe.left, safe.top, safe.right, safe.bottom)
        } catch (error: RuntimeException) {
            Log.w(TAG, "Window metrics unavailable; using display metrics", error)
            val display = overlayContext.resources.displayMetrics
            ScreenInfo(Rect(0, 0, display.widthPixels, display.heightPixels), 0, 0, 0, 0)
        }
    }

    private fun dpToPx(dp: Int): Int = (dp * overlayContext.resources.displayMetrics.density).toInt()

    private fun sizeForScreen(screen: ScreenInfo, requestedDp: Int): Int {
        val availableWidth = screen.bounds.width() - screen.left - screen.right
        val availableHeight = screen.bounds.height() - screen.top - screen.bottom
        return dpToPx(requestedDp).coerceAtMost(minOf(availableWidth, availableHeight).coerceAtLeast(1))
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(CHANNEL_ID, "GhostGirl overlay", NotificationManager.IMPORTANCE_LOW).apply {
            description = "Điều khiển nhân vật nổi GhostGirl"
            setShowBadge(false)
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    private fun buildNotification(): Notification {
        val open = PendingIntent.getActivity(this, 1,
            Intent(this, MainActivity::class.java).putExtra(MainActivity.EXTRA_OPENED_FROM_OVERLAY, true),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val stop = PendingIntent.getService(this, 2,
            Intent(this, GhostOverlayService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        return Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(getString(R.string.notification_title))
            .setContentText(getString(R.string.notification_text))
            .setContentIntent(open)
            .setOngoing(true)
            .addAction(Notification.Action.Builder(
                Icon.createWithResource(this, R.drawable.ic_notification), "Dừng", stop).build())
            .build()
    }

    companion object {
        private const val TAG = "GhostOverlayService"
        const val ACTION_START = "com.ghostgirl.companion.START"
        const val ACTION_STOP = "com.ghostgirl.companion.STOP"
        const val ACTION_UPDATE = "com.ghostgirl.companion.UPDATE"
        const val ACTION_PREVIEW = "com.ghostgirl.companion.PREVIEW"
        const val ACTION_TORCH = "com.ghostgirl.companion.TORCH"
        const val EXTRA_MOOD = "mood"
        private const val CHATGPT_PACKAGE = "com.openai.chatgpt"
        private const val CHANNEL_ID = "ghostgirl_overlay"
        private const val NOTIFICATION_ID = 1001

        @Volatile var isOverlayVisible: Boolean = false
            private set
    }
}
