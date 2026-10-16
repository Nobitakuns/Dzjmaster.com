# GhostGirl Android 1.1

Native Kotlin + Jetpack Compose Android project for a floating pixel-art companion. The overlay uses `WindowManager.TYPE_APPLICATION_OVERLAY`; the settings screen uses Compose. It does not need an OpenAI API key and does not connect to any API.

[Download GhostGirl Android 1.1.0 debug APK](https://github.com/Nobitakuns/Dzjmaster.com/releases/download/ghostgirl-v1.1.0/GhostGirl-Android-V1.1.0-debug.apk). SHA-256: `e91e33f8bd4b6deef0e0961fcc33c92b93d4e64ed9360810e2fd42326091e7bf`. The release APK has version code 4 and installs over earlier versions when signed with the same debug key.

## Build and install

Requirements: Android Studio with JDK 17 or 21, Android SDK Platform 36 and Build Tools 36.0.0. The project includes a Gradle wrapper. Open this repository folder as a project in Android Studio, or run:

```bash
export ANDROID_HOME=/path/to/Android/Sdk
./gradlew testDebugUnitTest assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

Debug APK: `app/build/outputs/apk/debug/app-debug.apk`. Minimum Android version is Android 11 (API 30); target SDK is 36 for Android 16. It is intended for modern phones, including the Galaxy Z Fold5. A Fold5 or Android 16 device is required to verify its real display behavior; a Linux build alone does not establish device compatibility.

## First run and controls

1. Open GhostGirl and tap **Cấp quyền và bắt đầu**. Android opens the system screen for **Display over other apps**; grant it to GhostGirl.
2. GhostGirl requests notification permission on Android 13+. Denying this permission does not prevent its foreground service, but the persistent notification may not appear in the notification shade.
3. Tap **Bắt đầu nhân vật nổi** if the system returned to the app without starting it. A small transparent character appears above other apps.
4. Drag the character to move it. It snaps to the nearest screen edge when enabled. Long press it to open GhostGirl settings.
5. Single tap the character to launch the installed official ChatGPT Android app through its normal launcher activity. If absent, GhostGirl opens the ChatGPT Play Store listing (or its web listing). Single tap waits 330 ms so a second/third tap can be recognized.
6. Double tap for a happy reaction; triple tap to switch to the next character. You can also select a character from the settings screen. A drag or long press cancels any unfinished tap sequence.
7. Use **Dừng nhân vật nổi** or the notification **Dừng** action to remove the overlay and stop the service.

If the floating character does not appear after tapping **Bắt đầu nhân vật nổi**, the app now shows a specific startup error instead of silently reverting to the start button. Check the on-screen message and Android's **Display over other apps** setting. The service also writes the full exception to Logcat under `GhostOverlayService` for diagnosis. The app starts its foreground service before requesting optional notification permission; notification denial does not block the overlay. Real-device verification on a Galaxy Z Fold5 is still required.

V1.0.2 uses the service context for the overlay window to avoid window-token mismatches on vendor Android builds. It also saves a short local crash reason and shows it under **Nhân vật nổi** when the app is reopened. If Android still closes GhostGirl, send a screenshot of that reason; it is stored only on the device and is never uploaded.

GhostGirl does **not** start ChatGPT Voice, automate accessibility actions, use undocumented deep links, listen to speech, or read other apps. The app requests no Internet permission. The launcher package is `com.openai.chatgpt`; package visibility is declared in `<queries>`.

## Animation and assets

`app/src/main/assets/ghostgirl_atlas.png` is transparent **prototype art** inspired by the supplied visual references. The five new `_sheet.png` assets are transparent cutouts adapted from the attached character concept sheets: Mimi (lavender cat hoodie), Sunny (orange hair and headset), Ruby (red jacket), Mèo Cam (tabby cat), and Yuki (white cat hoodie). These are **reference-derived prototype pose sheets**, not original production sprite atlases or frame-by-frame animations. Some edges may need manual pixel cleanup. Only use/distribute these art assets if you hold the necessary rights to the supplied references.

`GhostSpriteView` chooses a matching pose crop for each character and applies low-cost motion to it. Happy reacts to double tap, walking to drag, reacting to long press or character change, and sleeping after one idle minute. All seven moods can be previewed in settings. Talking and sad are preview states; there is no ChatGPT state integration.

To replace the art, provide a licensed transparent PNG and update the corresponding asset name and crop coordinates in `GhostCharacter.bounds` (or `GhostAtlas.bounds` for the original GhostGirl). The overlay fits each crop within a square view. Bitmap sampling disables filtering for sharp pixels.

## Service and foldable behavior

The overlay is a user-started foreground service with the Android `specialUse` service type, a persistent notification and a stop action. It uses the documented overlay permission flow. The window does not take keyboard focus. When the screen turns off, animation callbacks stop; idle and sleeping states update at a lower rate. The service is `START_NOT_STICKY` and does not auto-start after reboot.

On rotation and display changes, the service reads current window metrics and safe insets, then clamps the saved position into the new bounds. This is intended to handle Fold5 inner and cover displays. Screen-edge snapping and settings have pure unit tests. Publishing to Google Play may require a policy declaration for `SYSTEM_ALERT_WINDOW` and `FOREGROUND_SERVICE_SPECIAL_USE`; this debug build is for direct installation and testing.

## Tests

```bash
./gradlew testDebugUnitTest
```

The tests cover settings limits, overlay bounds/snap logic on narrow folded dimensions, atlas and character crop mapping, character cycling, and gesture timing/cancellation. Manual device checks still needed: permission grant/revoke, starting/stopping the service, single/double/triple tap, long press settings, drag and edge snap, notification stop, changing size/opacity/speed/character, screen off battery behavior, and unfolding/rotation on a Galaxy Z Fold5 with Android 16.

The cloud build runs `testDebugUnitTest`, `assembleDebug`, `lintDebug`, `apksigner verify`, and `zipalign -c`. No physical Galaxy Z Fold5 was available for installation testing.
