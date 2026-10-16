package com.ghostgirl.companion

import android.app.Application
import android.annotation.SuppressLint
import android.os.Process
import com.ghostgirl.companion.model.GhostSettingsStore

/** Keep a short local crash reason so it can be shown after Android restarts the app. */
class GhostGirlApplication : Application() {
    @SuppressLint("ApplySharedPref", "UseKtx")
    override fun onCreate() {
        super.onCreate()
        val previous = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, error ->
            try {
                val appFrame = error.stackTrace.firstOrNull {
                    it.className.startsWith("com.ghostgirl.companion")
                } ?: error.stackTrace.firstOrNull()
                val reason = buildString {
                    append(error.javaClass.simpleName)
                    error.message?.let { append(": ").append(it.take(180)) }
                    appFrame?.let { append(" tại ").append(it.className.substringAfterLast('.'))
                        .append(':').append(it.lineNumber) }
                }
                // The process is about to exit, so this record must be written synchronously.
                getSharedPreferences("ghostgirl_settings", MODE_PRIVATE).edit()
                    .putString(GhostSettingsStore.KEY_LAST_FATAL, reason)
                    .commit()
            } catch (_: Throwable) {
                // Preserve Android's own crash handling even if storage is unavailable.
            }
            if (previous != null) previous.uncaughtException(thread, error)
            else Process.killProcess(Process.myPid())
        }
    }
}
