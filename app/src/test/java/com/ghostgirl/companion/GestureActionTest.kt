package com.ghostgirl.companion

import com.ghostgirl.companion.model.GestureAction
import org.junit.Assert.assertEquals
import org.junit.Test

class GestureActionTest {
    @Test fun oldOrUnknownPreferenceKeepsGestureDefaults() {
        assertEquals(GestureAction.HAPPY,
            GestureAction.fromName(null, GestureAction.HAPPY))
        assertEquals(GestureAction.NEXT_CHARACTER,
            GestureAction.fromName("removed", GestureAction.NEXT_CHARACTER))
    }

    @Test fun eachSelectableActionRoundTripsThroughPreferences() {
        GestureAction.entries.forEach { action ->
            assertEquals(action, GestureAction.fromName(action.name, GestureAction.HAPPY))
        }
    }
}
