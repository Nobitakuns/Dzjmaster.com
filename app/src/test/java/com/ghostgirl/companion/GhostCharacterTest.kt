package com.ghostgirl.companion

import com.ghostgirl.companion.model.GhostCharacter
import com.ghostgirl.companion.model.GhostMood
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class GhostCharacterTest {
    @Test fun cyclesThroughAllChoicesAndWraps() {
        var next = GhostCharacter.GHOST_GIRL
        val visited = mutableSetOf<GhostCharacter>()
        repeat(GhostCharacter.entries.size) {
            visited += next
            next = next.next()
        }
        assertEquals(GhostCharacter.entries.toSet(), visited)
        assertEquals(GhostCharacter.GHOST_GIRL, next)
    }

    @Test fun everyMoodCropFitsSheet() {
        GhostCharacter.entries.forEach { character ->
            GhostMood.entries.forEach { mood ->
                val bounds = character.bounds(1451, 1084, mood)
                assertTrue(bounds.left >= 0 && bounds.left < bounds.right && bounds.right <= 1451)
                assertTrue(bounds.top >= 0 && bounds.top < bounds.bottom && bounds.bottom <= 1084)
            }
        }
    }

    @Test fun unknownSavedCharacterFallsBack() {
        assertEquals(GhostCharacter.GHOST_GIRL, GhostCharacter.fromId("removed"))
    }
}
