package com.ghostgirl.companion.overlay

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import android.os.SystemClock
import android.view.View
import androidx.core.graphics.withSave
import com.ghostgirl.companion.model.GhostAtlas
import com.ghostgirl.companion.model.GhostMood
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.sin

/** Draws one atlas cell at a time; subtle transforms make each PNG pose animate. */
class GhostSpriteView(context: Context) : View(context) {
    private val atlas: Bitmap = context.assets.open("ghostgirl_atlas.png").use { stream ->
        BitmapFactory.decodeStream(stream, null, BitmapFactory.Options().apply { inScaled = false })
            ?: error("Missing GhostGirl sprite atlas")
    }
    private val paint = Paint().apply {
        isFilterBitmap = false
        isDither = false
    }
    private val destination = RectF()
    private val source = Rect()
    private val density = resources.displayMetrics.density
    private var mood = GhostMood.IDLE
    private var moodUntilMs = 0L
    private var idleSinceMs = SystemClock.uptimeMillis()
    private var animationSpeed = 1f
    private var screenActive = true
    var onClicked: (() -> Unit)? = null
    var onLongPressed: (() -> Unit)? = null

    private val ticker = object : Runnable {
        override fun run() {
            if (!isAttachedToWindow || !screenActive) return
            invalidate()
            postDelayed(this, nextTickMs())
        }
    }

    fun showMood(next: GhostMood, durationMs: Long = 0L) {
        mood = next
        val now = SystemClock.uptimeMillis()
        moodUntilMs = if (durationMs > 0L) now + durationMs else 0L
        idleSinceMs = now
        invalidate()
        restartTicker()
    }

    fun setAnimationSpeed(value: Float) {
        animationSpeed = value.coerceIn(0.5f, 2f)
        restartTicker()
    }

    fun setScreenActive(active: Boolean) {
        screenActive = active
        restartTicker()
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        restartTicker()
    }

    override fun onDetachedFromWindow() {
        removeCallbacks(ticker)
        super.onDetachedFromWindow()
    }

    override fun performClick(): Boolean {
        super.performClick()
        onClicked?.invoke()
        return true
    }

    override fun performLongClick(): Boolean {
        val handled = super.performLongClick()
        onLongPressed?.invoke()
        return handled || onLongPressed != null
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        if (atlas.isRecycled) return
        val now = SystemClock.uptimeMillis()
        if (moodUntilMs > 0L && now >= moodUntilMs) {
            mood = GhostMood.IDLE
            moodUntilMs = 0L
            idleSinceMs = now
        }
        if (mood == GhostMood.IDLE && now - idleSinceMs > 60_000L) mood = GhostMood.SLEEPING

        val cell = GhostAtlas.bounds(atlas.width, atlas.height, mood)
        source.set(cell.left, cell.top, cell.right, cell.bottom)
        destination.set(0f, 0f, width.toFloat(), height.toFloat())
        val seconds = now / 1000.0 * animationSpeed
        val wave = sin(seconds * 2.0 * PI)
        val unit = density
        canvas.withSave {
            when (mood) {
                GhostMood.IDLE -> translate(0f, (wave * 1.3 * unit).toFloat())
                GhostMood.HAPPY -> translate(0f, (-abs(wave) * 5.0 * unit).toFloat())
                GhostMood.SAD -> rotate((wave * 1.4).toFloat(), width / 2f, height / 2f)
                GhostMood.SLEEPING -> scale(1f + (wave * 0.012).toFloat(), 1f, width / 2f, height / 2f)
                GhostMood.WALKING -> {
                    translate((wave * 2.4 * unit).toFloat(), (-abs(wave) * 2.0 * unit).toFloat())
                }
                GhostMood.TALKING -> scale(1f, 1f + (wave * 0.019).toFloat(), width / 2f, height / 2f)
                GhostMood.REACTING -> rotate((wave * 3.5).toFloat(), width / 2f, height / 2f)
            }
            drawBitmap(atlas, source, destination, paint)
        }
    }

    private fun nextTickMs(): Long {
        val base = when (mood) {
            GhostMood.SLEEPING -> 700L
            GhostMood.IDLE, GhostMood.SAD -> 350L
            else -> 140L
        }
        return (base / animationSpeed).toLong().coerceAtLeast(70L)
    }

    private fun restartTicker() {
        removeCallbacks(ticker)
        if (isAttachedToWindow && screenActive) postDelayed(ticker, nextTickMs())
    }
}
