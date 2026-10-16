package com.ghostgirl.companion

import com.ghostgirl.companion.model.GhostAtlas
import com.ghostgirl.companion.model.GhostMood
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class GhostAtlasTest {
    @Test fun everyMoodHasUniqueValidCell() {
        assertEquals(7, GhostMood.entries.map { it.cell }.distinct().size)
        for (mood in GhostMood.entries) {
            val bounds = GhostAtlas.bounds(1774, 887, mood)
            assertTrue(bounds.left >= 0 && bounds.top >= 0)
            assertTrue(bounds.right <= 1774 && bounds.bottom <= 887)
            assertTrue(bounds.right > bounds.left && bounds.bottom > bounds.top)
        }
    }

    @Test fun missingPreviewMoodFallsBackToIdle() {
        assertEquals(GhostMood.IDLE, GhostMood.fromName("unknown"))
        assertEquals(GhostMood.TALKING, GhostMood.fromName("TALKING"))
    }
}
