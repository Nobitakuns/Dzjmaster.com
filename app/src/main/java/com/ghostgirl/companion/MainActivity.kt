package com.ghostgirl.companion

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.core.content.ContextCompat
import androidx.core.net.toUri
import com.ghostgirl.companion.model.GhostMood
import com.ghostgirl.companion.model.GhostSettings
import com.ghostgirl.companion.model.GhostSettingsStore
import com.ghostgirl.companion.overlay.GhostOverlayService
import com.ghostgirl.companion.ui.GhostGirlApp

class MainActivity : ComponentActivity() {
    private lateinit var settingsStore: GhostSettingsStore
    private var ghostSettings by mutableStateOf(GhostSettings())
    private var overlayGranted by mutableStateOf(false)
    private var notificationsGranted by mutableStateOf(true)
    private var overlayRunning by mutableStateOf(false)
    private var openedFromOverlay by mutableStateOf(false)

    private val overlayPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult(),
    ) {
        refreshStatus()
        if (overlayGranted) continueStartFlow()
    }

    private val notificationPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission(),
    ) {
        refreshStatus()
        // Android permits a foreground service even when notification permission is denied.
        startOverlayService()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        settingsStore = GhostSettingsStore(this)
        ghostSettings = settingsStore.read()
        openedFromOverlay = intent.getBooleanExtra(EXTRA_OPENED_FROM_OVERLAY, false)
        refreshStatus()
        setContent {
            GhostGirlApp(
                settings = ghostSettings,
                overlayGranted = overlayGranted,
                notificationsGranted = notificationsGranted,
                overlayRunning = overlayRunning,
                openedFromOverlay = openedFromOverlay,
                onSettingsChanged = { next ->
                    ghostSettings = next.normalized()
                    settingsStore.save(ghostSettings)
                },
                onRequestOverlay = ::startOverlayFlow,
                onStopOverlay = ::stopOverlay,
                onPreviewMood = ::previewMood,
            )
        }
    }

    override fun onResume() {
        super.onResume()
        if (::settingsStore.isInitialized) refreshStatus()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        openedFromOverlay = intent.getBooleanExtra(EXTRA_OPENED_FROM_OVERLAY, false)
        refreshStatus()
    }

    private fun refreshStatus() {
        overlayGranted = Settings.canDrawOverlays(this)
        notificationsGranted = Build.VERSION.SDK_INT < 33 ||
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        overlayRunning = GhostOverlayService.isOverlayVisible
    }

    private fun startOverlayFlow() {
        if (!Settings.canDrawOverlays(this)) {
            val permissionIntent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                "package:$packageName".toUri())
            overlayPermissionLauncher.launch(permissionIntent)
            return
        }
        continueStartFlow()
    }

    private fun continueStartFlow() {
        if (Build.VERSION.SDK_INT >= 33 && !notificationsGranted) {
            notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
        } else {
            startOverlayService()
        }
    }

    private fun startOverlayService() {
        if (!Settings.canDrawOverlays(this)) return
        ContextCompat.startForegroundService(this,
            Intent(this, GhostOverlayService::class.java).setAction(GhostOverlayService.ACTION_START))
        overlayRunning = true
    }

    private fun stopOverlay() {
        if (GhostOverlayService.isOverlayVisible) {
            startService(Intent(this, GhostOverlayService::class.java).setAction(GhostOverlayService.ACTION_STOP))
        }
        overlayRunning = false
    }

    private fun previewMood(mood: GhostMood) {
        if (GhostOverlayService.isOverlayVisible) {
            startService(Intent(this, GhostOverlayService::class.java)
                .setAction(GhostOverlayService.ACTION_PREVIEW)
                .putExtra(GhostOverlayService.EXTRA_MOOD, mood.name))
        }
    }

    companion object {
        const val EXTRA_OPENED_FROM_OVERLAY = "opened_from_overlay"
    }
}
