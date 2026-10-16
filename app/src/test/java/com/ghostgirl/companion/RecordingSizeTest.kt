package com.ghostgirl.companion

import com.ghostgirl.companion.capture.RecordingSize
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class RecordingSizeTest {
    @Test fun foldableScreenFitsEncoderLimitWithEvenDimensions() {
        val size = RecordingSize.fit(2176, 1812)
        assertTrue(size.width <= 1920 && size.height <= 1920)
        assertEquals(0, size.width % 2)
        assertEquals(0, size.height % 2)
    }

    @Test fun phonePortraitKeepsOrientation() {
        val size = RecordingSize.fit(1080, 2400)
        assertTrue(size.height > size.width)
        assertEquals(1920, size.height)
    }
}
