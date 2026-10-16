package com.ghostgirl.companion.model

enum class GestureAction(val label: String) {
    HAPPY("Phản ứng vui"),
    NEXT_CHARACTER("Đổi nhân vật"),
    OPEN_APP("Mở ứng dụng đã chọn"),
    FLASHLIGHT("Bật/tắt đèn pin"),
    SCREENSHOT("Chụp màn hình"),
    SCREEN_RECORD("Bắt đầu/dừng quay màn hình");

    companion object {
        fun fromName(value: String?, fallback: GestureAction): GestureAction =
            entries.firstOrNull { it.name == value } ?: fallback
    }
}

data class LaunchableApp(val label: String, val component: String)
