package com.ghostgirl.companion.model

/** Resolves one, two, or three taps without firing a shorter gesture too early. */
class TapSequence(private val intervalMs: Long = 330L) {
    enum class Gesture { SINGLE, DOUBLE, TRIPLE }

    private var count = 0
    private var lastTapMs = 0L

    fun tap(nowMs: Long): Gesture? {
        val expired = if (count > 0 && nowMs - lastTapMs > intervalMs) finish() else null
        count++
        lastTapMs = nowMs
        if (count == 3) return Gesture.TRIPLE.also { cancel() }
        return expired
    }

    fun flush(nowMs: Long): Gesture? =
        if (count > 0 && nowMs - lastTapMs >= intervalMs) finish() else null

    fun hasPending(): Boolean = count > 0

    fun cancel() {
        count = 0
        lastTapMs = 0L
    }

    private fun finish(): Gesture {
        val gesture = if (count == 1) Gesture.SINGLE else Gesture.DOUBLE
        cancel()
        return gesture
    }
}
