package com.ghostgirl.companion

import android.app.Activity
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import com.ghostgirl.companion.capture.ScreenCaptureService

/** Starts Android's documented one-time MediaProjection consent flow. */
class CaptureConsentActivity : ComponentActivity() {
    private val consent = registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
        val resultData = result.data
        if (result.resultCode == Activity.RESULT_OK && resultData != null) {
            val action = if (intent.getBooleanExtra(EXTRA_RECORD, false))
                ScreenCaptureService.ACTION_RECORD else ScreenCaptureService.ACTION_SCREENSHOT
            try {
                ContextCompat.startForegroundService(this,
                    Intent(this, ScreenCaptureService::class.java).setAction(action)
                        .putExtra(ScreenCaptureService.EXTRA_RESULT_CODE, result.resultCode)
                        .putExtra(ScreenCaptureService.EXTRA_RESULT_DATA, resultData))
            } catch (_: RuntimeException) {
                Toast.makeText(this, "Không khởi động được chụp/quay màn hình", Toast.LENGTH_LONG).show()
            }
        }
        finish()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (savedInstanceState == null) {
            val projectionManager = getSystemService(MediaProjectionManager::class.java)
            consent.launch(projectionManager.createScreenCaptureIntent())
        }
    }

    companion object {
        const val EXTRA_RECORD = "record"
    }
}
