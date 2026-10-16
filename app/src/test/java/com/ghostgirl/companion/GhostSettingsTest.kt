package com.ghostgirl.companion

import com.ghostgirl.companion.model.GhostSettings
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

class GhostSettingsTest {
    @Test fun settingsStayInSupportedRanges() {
        val settings = GhostSettings(sizeDp = 400, opacity = 0.1f,
            animationSpeed = 8f, snapToEdge = false).normalized()
        assertEquals(240, settings.sizeDp)
        assertEquals(0.4f, settings.opacity, 0.001f)
        assertEquals(2f, settings.animationSpeed, 0.001f)
        assertFalse(settings.snapToEdge)
    }

    @Test fun minimumSizeAndSpeedAreEnforced() {
        val settings = GhostSettings(sizeDp = 10, animationSpeed = 0.1f).normalized()
        assertEquals(72, settings.sizeDp)
        assertEquals(0.5f, settings.animationSpeed, 0.001f)
    }
}
