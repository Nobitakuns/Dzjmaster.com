package com.ghostgirl.companion.capture

data class RecordingSize(val width: Int, val height: Int) {
    companion object {
        /** H.264 encoders expect even dimensions; cap the long edge for foldable displays. */
        fun fit(screenWidth: Int, screenHeight: Int): RecordingSize {
            require(screenWidth > 0 && screenHeight > 0)
            val scale = minOf(1f, 1920f / maxOf(screenWidth, screenHeight))
            return RecordingSize(
                ((screenWidth * scale).toInt() and -2).coerceAtLeast(2),
                ((screenHeight * scale).toInt() and -2).coerceAtLeast(2),
            )
        }
    }
}
