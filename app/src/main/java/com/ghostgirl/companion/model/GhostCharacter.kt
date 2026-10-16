package com.ghostgirl.companion.model

/** Five optional pixel-art characters come from the supplied reference sheets. */
enum class GhostCharacter(val id: String, val label: String, val asset: String) {
    GHOST_GIRL("ghostgirl", "PixiePop", "ghostgirl_atlas.png"),
    MIMI("mimi", "Mimi mèo tím", "mimi_sheet.png"),
    SUNNY("sunny", "Sunny radio", "sunny_sheet.png"),
    RUBY("ruby", "Ruby tim đỏ", "ruby_sheet.png"),
    TABBY("tabby", "Mèo Cam", "tabby_sheet.png"),
    YUKI("yuki", "Yuki mèo trắng", "yuki_sheet.png"),
    MAIMAI("maimai", "Mai Mai hầu gái", "maimai_sheet.png");

    fun bounds(width: Int, height: Int, mood: GhostMood): AtlasBounds {
        if (this == GHOST_GIRL) return GhostAtlas.bounds(width, height, mood)
        // The reference sheets are expression sheets, not uniform frame atlases. These
        // crops select whole poses while keeping the image assets replaceable.
        val crop = when (mood) {
            GhostMood.IDLE -> floatArrayOf(.02f, .02f, .30f, .54f)
            GhostMood.HAPPY -> floatArrayOf(.45f, .30f, .59f, .54f)
            GhostMood.SAD -> when (this) {
                RUBY -> floatArrayOf(.84f, .30f, .99f, .54f)
                TABBY, YUKI, MAIMAI -> floatArrayOf(.59f, .30f, .74f, .54f)
                else -> floatArrayOf(.16f, .55f, .30f, .77f)
            }
            GhostMood.SLEEPING -> if (this == RUBY)
                floatArrayOf(.70f, .55f, .84f, .77f)
            else floatArrayOf(.84f, .30f, .99f, .54f)
            GhostMood.WALKING -> floatArrayOf(.30f, .30f, .45f, .54f)
            GhostMood.TALKING -> floatArrayOf(.02f, .55f, .16f, .77f)
            GhostMood.REACTING -> floatArrayOf(.30f, .55f, .43f, .77f)
        }
        return AtlasBounds(
            (crop[0] * width).toInt().coerceIn(0, width - 1),
            (crop[1] * height).toInt().coerceIn(0, height - 1),
            (crop[2] * width).toInt().coerceIn(1, width),
            (crop[3] * height).toInt().coerceIn(1, height),
        )
    }

    fun next(): GhostCharacter = entries[(ordinal + 1) % entries.size]

    companion object {
        fun fromId(value: String?): GhostCharacter = entries.firstOrNull { it.id == value } ?: GHOST_GIRL
    }
}
