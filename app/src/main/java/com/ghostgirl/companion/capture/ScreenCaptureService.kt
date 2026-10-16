package com.ghostgirl.companion.capture

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.ContentValues
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.drawable.Icon
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Environment
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.provider.MediaStore
import android.util.Log
import android.view.WindowManager
import android.widget.Toast
import com.ghostgirl.companion.MainActivity
import com.ghostgirl.companion.R
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/** Records a user-stoppable video after MediaProjection consent. */
class ScreenCaptureService : Service() {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var workerThread: HandlerThread? = null
    private var worker: Handler? = null
    private var projection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var recorder: MediaRecorder? = null
    private var outputFd: ParcelFileDescriptor? = null
    private var outputUri: Uri? = null
    private var outputFinished = false
    private var stopping = false
    private var recording = false

    private val projectionCallback = object : MediaProjection.Callback() {
        override fun onStop() {
            if (!stopping) mainHandler.post { stopSelf() }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }
        if (intent?.action != ACTION_RECORD) {
            stopSelf()
            return START_NOT_STICKY
        }
        if (projection != null) return START_NOT_STICKY
        val resultCode = intent?.getIntExtra(EXTRA_RESULT_CODE, 0) ?: 0
        @Suppress("DEPRECATION")
        val resultData = intent?.getParcelableExtra<Intent>(EXTRA_RESULT_DATA)
        if (resultCode != android.app.Activity.RESULT_OK || resultData == null) {
            stopSelf()
            return START_NOT_STICKY
        }
        try {
            createNotificationChannel()
            startForeground(NOTIFICATION_ID, buildNotification(),
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)
            workerThread = HandlerThread("GhostGirlCapture").also { it.start() }
            worker = Handler(workerThread!!.looper)
            val manager = getSystemService(MediaProjectionManager::class.java)
            projection = manager.getMediaProjection(resultCode, resultData)
                ?: error("Android did not grant screen capture")
            projection!!.registerCallback(projectionCallback, mainHandler)
            val bounds = getSystemService(WindowManager::class.java).currentWindowMetrics.bounds
            val width = bounds.width().coerceAtLeast(2)
            val height = bounds.height().coerceAtLeast(2)
            val density = resources.displayMetrics.densityDpi
            startRecording(width, height, density)
        } catch (error: Exception) {
            Log.e(TAG, "Cannot start screen capture", error)
            Toast.makeText(this, "Không quay được: ${error.message.orEmpty().take(80)}", Toast.LENGTH_LONG).show()
            stopSelf()
        }
        return START_NOT_STICKY
    }

    @Suppress("DEPRECATION")
    private fun startRecording(screenWidth: Int, screenHeight: Int, density: Int) {
        val (width, height) = RecordingSize.fit(screenWidth, screenHeight)
        val values = ContentValues().apply {
            put(MediaStore.Video.Media.DISPLAY_NAME, "PixiePop_${timestamp()}.mp4")
            put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
            put(MediaStore.Video.Media.RELATIVE_PATH, "${Environment.DIRECTORY_MOVIES}/PixiePop")
            put(MediaStore.Video.Media.IS_PENDING, 1)
        }
        outputUri = contentResolver.insert(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, values)
            ?: error("Cannot create video file")
        outputFd = contentResolver.openFileDescriptor(outputUri!!, "w")
            ?: error("Cannot write video")
        val video = MediaRecorder().apply {
            setVideoSource(MediaRecorder.VideoSource.SURFACE)
            setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            setVideoEncoder(MediaRecorder.VideoEncoder.H264)
            setVideoSize(width, height)
            setVideoEncodingBitRate(3_000_000)
            setVideoFrameRate(30)
            setOutputFile(outputFd!!.fileDescriptor)
            prepare()
        }
        recorder = video
        virtualDisplay = projection!!.createVirtualDisplay("GhostGirlRecording", width, height,
            density, DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR, video.surface, null, worker)
        video.start()
        recording = true
        isRecording = true
        Toast.makeText(this, "Đang quay màn hình. Chạm lại hoặc bấm Dừng ở thông báo.", Toast.LENGTH_LONG).show()
    }

    private fun finishOutput() {
        outputUri?.let { uri ->
            contentResolver.update(uri, ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) }, null, null)
        }
        outputFinished = true
    }

    override fun onDestroy() {
        stopping = true
        isRecording = false
        if (recording) {
            try {
                recorder?.stop()
                finishOutput()
                Toast.makeText(this, "Đã lưu video vào Movies/PixiePop", Toast.LENGTH_SHORT).show()
            } catch (error: RuntimeException) {
                Log.e(TAG, "Video recording could not be saved", error)
            }
        }
        runCatching { recorder?.reset() }
        runCatching { recorder?.release() }
        runCatching { virtualDisplay?.release() }
        runCatching { projection?.unregisterCallback(projectionCallback) }
        runCatching { projection?.stop() }
        runCatching { outputFd?.close() }
        if (!outputFinished) outputUri?.let { uri -> runCatching { contentResolver.delete(uri, null, null) } }
        workerThread?.quitSafely()
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }

    private fun timestamp(): String = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())

    private fun createNotificationChannel() {
        getSystemService(NotificationManager::class.java).createNotificationChannel(
            NotificationChannel(CHANNEL_ID, "PixiePop chụp/quay màn hình", NotificationManager.IMPORTANCE_LOW))
    }

    private fun buildNotification(): Notification {
        val stop = PendingIntent.getService(this, 42,
            Intent(this, ScreenCaptureService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val open = PendingIntent.getActivity(this, 43, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        return Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("PixiePop đang quay màn hình")
            .setContentText("Chạm Dừng để lưu video")
            .setContentIntent(open)
            .setOngoing(true)
            .addAction(Notification.Action.Builder(
                Icon.createWithResource(this, R.drawable.ic_notification), "Dừng", stop).build())
            .build()
    }

    companion object {
        private const val TAG = "ScreenCaptureService"
        private const val CHANNEL_ID = "ghostgirl_capture"
        private const val NOTIFICATION_ID = 1002
        const val ACTION_RECORD = "com.ghostgirl.companion.RECORD"
        const val ACTION_STOP = "com.ghostgirl.companion.STOP_CAPTURE"
        const val EXTRA_RESULT_CODE = "result_code"
        const val EXTRA_RESULT_DATA = "result_data"

        @Volatile var isRecording: Boolean = false
            private set
    }
}
