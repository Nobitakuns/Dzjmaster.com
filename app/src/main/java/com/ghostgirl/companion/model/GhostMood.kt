package com.ghostgirl.companion.model

/** Seven prototype poses in the replaceable 4 x 2 transparent PNG atlas. */
enum class GhostMood(val cell: Int, val label: String) {
    IDLE(0, "Đứng yên"),
    HAPPY(1, "Vui vẻ"),
    SAD(2, "Buồn"),
    SLEEPING(3, "Ngủ"),
    WALKING(4, "Đi bộ"),
    TALKING(5, "Trò chuyện"),
    REACTING(6, "Bất ngờ");

    companion object {
        fun fromName(value: String?): GhostMood = entries.firstOrNull { it.name == value } ?: IDLE
    }
}

data class AtlasBounds(val left: Int, val top: Int, val right: Int, val bottom: Int)

object GhostAtlas {
    fun bounds(width: Int, height: Int, mood: GhostMood): AtlasBounds {
        require(width >= 4 && height >= 2)
        val column = mood.cell % 4
        val row = mood.cell / 4
        return AtlasBounds(
            left = column * width / 4,
            top = row * height / 2,
            right = (column + 1) * width / 4,
            bottom = (row + 1) * height / 2,
        )
    }
}
