package com.ghostgirl.companion.capture

import android.accessibilityservice.AccessibilityService
import android.content.ContentValues
import android.content.Intent
import android.graphics.Bitmap
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.util.Log
import android.view.Display
import android.view.accessibility.AccessibilityEvent
import android.widget.Toast
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/** Uses only Android's documented display screenshot API; no event or gesture automation. */
class InstantScreenshotService : AccessibilityService() {
    private val worker = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val busy = AtomicBoolean(false)

    override fun onServiceConnected() {
        super.onServiceConnected()
        serviceInfo = serviceInfo.apply { eventTypes = 0 }
        activeService = this
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) = Unit

    override fun onInterrupt() = Unit

    override fun onUnbind(intent: Intent?): Boolean {
        if (activeService === this) activeService = null
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        if (activeService === this) activeService = null
        worker.shutdown()
        super.onDestroy()
    }

    private fun capture(displayId: Int) {
        if (!busy.compareAndSet(false, true)) return
        try {
            takeScreenshot(displayId, worker, object : TakeScreenshotCallback {
                override fun onSuccess(result: ScreenshotResult) {
                    val buffer = result.hardwareBuffer
                    try {
                        val hardwareBitmap = Bitmap.wrapHardwareBuffer(buffer, result.colorSpace)
                            ?: error("Không đọc được ảnh màn hình")
                        val bitmap = hardwareBitmap.copy(Bitmap.Config.ARGB_8888, false)
                            ?: error("Không chuyển được ảnh màn hình")
                        try {
                            save(bitmap)
                            show("Đã lưu ảnh vào Pictures/PixiePop")
                        } finally {
                            bitmap.recycle()
                            hardwareBitmap.recycle()
                        }
                    } catch (error: Exception) {
                        Log.e(TAG, "Cannot save display screenshot", error)
                        show("Không lưu được ảnh màn hình")
                    } finally {
                        buffer.close()
                        busy.set(false)
                    }
                }

                override fun onFailure(errorCode: Int) {
                    Log.w(TAG, "Android rejected display screenshot: $errorCode")
                    show("Không chụp được màn hình này; ứng dụng có thể chặn chụp ảnh")
                    busy.set(false)
                }
            })
        } catch (error: RuntimeException) {
            Log.e(TAG, "Cannot request display screenshot", error)
            show("Không chụp được màn hình; hãy kiểm tra quyền chụp ảnh")
            busy.set(false)
        }
    }

    private fun save(bitmap: Bitmap) {
        val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss_SSS", Locale.US).format(Date())
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, "PixiePop_$timestamp.png")
            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
            put(MediaStore.Images.Media.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/PixiePop")
            put(MediaStore.Images.Media.IS_PENDING, 1)
        }
        val uri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
            ?: error("Không tạo được tệp ảnh")
        var completed = false
        try {
            contentResolver.openOutputStream(uri)?.use { stream ->
                check(bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream))
            } ?: error("Không ghi được tệp ảnh")
            contentResolver.update(uri, ContentValues().apply {
                put(MediaStore.Images.Media.IS_PENDING, 0)
            }, null, null)
            completed = true
        } finally {
            if (!completed) contentResolver.delete(uri, null, null)
        }
    }

    private fun show(message: String) {
        mainHandler.post { Toast.makeText(this, message, Toast.LENGTH_SHORT).show() }
    }

    companion object {
        private const val TAG = "InstantScreenshotService"

        @Volatile private var activeService: InstantScreenshotService? = null

        fun isReady(): Boolean = activeService != null

        fun captureCurrentDisplay(displayId: Int = Display.DEFAULT_DISPLAY): Boolean {
            val service = activeService ?: return false
            service.capture(displayId)
            return true
        }
    }
}
