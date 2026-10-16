package com.ghostgirl.companion.model

import android.content.Context
import android.content.SharedPreferences
import androidx.core.content.edit

data class GhostSettings(
    val sizeDp: Int = 156,
    val opacity: Float = 0.96f,
    val animationSpeed: Float = 1f,
    val snapToEdge: Boolean = true,
) {
    fun normalized(): GhostSettings = copy(
        sizeDp = sizeDp.coerceIn(72, 240),
        opacity = opacity.coerceIn(0.4f, 1f),
        animationSpeed = animationSpeed.coerceIn(0.5f, 2f),
    )
}

data class OverlayPoint(val x: Int, val y: Int)

/** Pure positioning rules; screen dimensions are refreshed after each fold or rotation. */
object OverlayGeometry {
    fun clamp(
        position: OverlayPoint,
        screenWidth: Int,
        screenHeight: Int,
        overlaySize: Int,
        insetLeft: Int = 0,
        insetTop: Int = 0,
        insetRight: Int = 0,
        insetBottom: Int = 0,
    ): OverlayPoint {
        val maxX = (screenWidth - insetRight - overlaySize).coerceAtLeast(insetLeft)
        val maxY = (screenHeight - insetBottom - overlaySize).coerceAtLeast(insetTop)
        return OverlayPoint(
            position.x.coerceIn(insetLeft, maxX),
            position.y.coerceIn(insetTop, maxY),
        )
    }

    fun snapToNearestEdge(
        position: OverlayPoint,
        screenWidth: Int,
        screenHeight: Int,
        overlaySize: Int,
        insetLeft: Int = 0,
        insetTop: Int = 0,
        insetRight: Int = 0,
        insetBottom: Int = 0,
    ): OverlayPoint {
        val bounded = clamp(position, screenWidth, screenHeight, overlaySize,
            insetLeft, insetTop, insetRight, insetBottom)
        val rightEdge = (screenWidth - insetRight - overlaySize).coerceAtLeast(insetLeft)
        val x = if (bounded.x - insetLeft <= rightEdge - bounded.x) insetLeft else rightEdge
        return bounded.copy(x = x)
    }
}

class GhostSettingsStore(context: Context) {
    companion object {
        const val KEY_OVERLAY_ERROR = "overlay_error"
        const val KEY_OVERLAY_VISIBLE = "overlay_visible"
    }

    val preferences: SharedPreferences =
        context.getSharedPreferences("ghostgirl_settings", Context.MODE_PRIVATE)

    fun read(): GhostSettings = GhostSettings(
        sizeDp = preferences.getInt("size_dp", 156),
        opacity = preferences.getFloat("opacity", 0.96f),
        animationSpeed = preferences.getFloat("animation_speed", 1f),
        snapToEdge = preferences.getBoolean("snap_to_edge", true),
    ).normalized()

    fun save(settings: GhostSettings) {
        val safe = settings.normalized()
        preferences.edit {
            putInt("size_dp", safe.sizeDp)
            putFloat("opacity", safe.opacity)
            putFloat("animation_speed", safe.animationSpeed)
            putBoolean("snap_to_edge", safe.snapToEdge)
        }
    }

    fun position(): OverlayPoint? = if (preferences.contains("overlay_x") && preferences.contains("overlay_y")) {
        OverlayPoint(preferences.getInt("overlay_x", 0), preferences.getInt("overlay_y", 0))
    } else null

    fun savePosition(point: OverlayPoint) {
        preferences.edit {
            putInt("overlay_x", point.x)
            putInt("overlay_y", point.y)
        }
    }

    fun overlayError(): String? = preferences.getString(KEY_OVERLAY_ERROR, null)

    fun setOverlayError(message: String?) {
        preferences.edit {
            if (message == null) remove(KEY_OVERLAY_ERROR) else putString(KEY_OVERLAY_ERROR, message)
        }
    }

    fun setOverlayVisible(visible: Boolean) {
        preferences.edit { putBoolean(KEY_OVERLAY_VISIBLE, visible) }
    }
}
