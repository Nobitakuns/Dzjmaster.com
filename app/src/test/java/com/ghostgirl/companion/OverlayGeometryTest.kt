package com.ghostgirl.companion

import com.ghostgirl.companion.model.OverlayGeometry
import com.ghostgirl.companion.model.OverlayPoint
import org.junit.Assert.assertEquals
import org.junit.Test

class OverlayGeometryTest {
    @Test fun dragRemainsInsideSafeDisplayArea() {
        val actual = OverlayGeometry.clamp(OverlayPoint(9999, -80),
            screenWidth = 1100, screenHeight = 2200, overlaySize = 200,
            insetLeft = 10, insetTop = 50, insetRight = 20, insetBottom = 80)
        assertEquals(OverlayPoint(880, 50), actual)
    }

    @Test fun snapChoosesNearestEdge() {
        val left = OverlayGeometry.snapToNearestEdge(OverlayPoint(240, 500),
            1000, 1800, 180, insetLeft = 16, insetRight = 24)
        val right = OverlayGeometry.snapToNearestEdge(OverlayPoint(700, 500),
            1000, 1800, 180, insetLeft = 16, insetRight = 24)
        assertEquals(16, left.x)
        assertEquals(796, right.x)
    }

    @Test fun narrowFoldedDisplayDoesNotOverflow() {
        val point = OverlayGeometry.clamp(OverlayPoint(700, 1400),
            420, 960, 500, insetLeft = 12, insetTop = 30, insetRight = 12, insetBottom = 30)
        assertEquals(12, point.x)
        assertEquals(430, point.y)
    }
}
