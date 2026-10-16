package com.ghostgirl.companion

import com.ghostgirl.companion.model.TapSequence
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Test

class TapSequenceTest {
    @Test fun singleWaitsUntilWindowCloses() {
        val taps = TapSequence()
        assertNull(taps.tap(1_000))
        assertNull(taps.flush(1_329))
        assertEquals(TapSequence.Gesture.SINGLE, taps.flush(1_330))
        assertFalse(taps.hasPending())
    }

    @Test fun doubleDoesNotAlsoFireSingle() {
        val taps = TapSequence()
        assertNull(taps.tap(1_000))
        assertNull(taps.tap(1_180))
        assertEquals(TapSequence.Gesture.DOUBLE, taps.flush(1_510))
        assertNull(taps.flush(2_000))
    }

    @Test fun tripleFiresImmediatelyOnce() {
        val taps = TapSequence()
        assertNull(taps.tap(1_000))
        assertNull(taps.tap(1_100))
        assertEquals(TapSequence.Gesture.TRIPLE, taps.tap(1_220))
        assertNull(taps.flush(2_000))
    }

    @Test fun dragOrLongPressCanCancelPendingTap() {
        val taps = TapSequence()
        taps.tap(1_000)
        taps.cancel()
        assertNull(taps.flush(2_000))
    }
}
