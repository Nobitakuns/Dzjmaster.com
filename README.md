# PixiePop Android 1.4

For the Apple Silicon Mac app, see [PixiePop for macOS](macos/PixiePop/README.md).

Native Kotlin + Jetpack Compose Android project for a floating pixel-art companion. The overlay uses `WindowManager.TYPE_APPLICATION_OVERLAY`; the settings screen uses Compose. It does not need an OpenAI API key and does not connect to any API.

[Download PixiePop Android 1.4.0 debug APK](https://github.com/Nobitakuns/Dzjmaster.com/releases/download/pixiepop-v1.4.0/PixiePop-Android-V1.4.0-debug.apk). SHA-256: `4b8e701af56bdcd00d93f4d189a52488146830ce83645bb65ac06758afbb600b`. The release APK has version code 7 and installs over earlier versions when signed with the same debug key. Its Android package ID remains `com.ghostgirl.companion` to preserve existing installations and settings.

## Build and install

Requirements: Android Studio with JDK 17 or 21, Android SDK Platform 36 and Build Tools 36.0.0. The project includes a Gradle wrapper. Open this repository folder as a project in Android Studio, or run:

```bash
export ANDROID_HOME=/path/to/Android/Sdk
./gradlew testDebugUnitTest assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

Debug APK: `app/build/outputs/apk/debug/app-debug.apk`. Minimum Android version is Android 11 (API 30); target SDK is 36 for Android 16. It is intended for modern phones, including the Galaxy Z Fold5. A Fold5 or Android 16 device is required to verify its real display behavior; a Linux build alone does not establish device compatibility.

## First run and controls

1. Open PixiePop and tap **Cấp quyền và bắt đầu**. Android opens the system screen for **Display over other apps**; grant it to PixiePop.
2. PixiePop requests notification permission on Android 13+. Denying this permission does not prevent its foreground service, but the persistent notification may not appear in the notification shade.
3. Tap **Bắt đầu nhân vật nổi** if the system returned to the app without starting it. A small transparent character appears above other apps.
4. Drag the character to move it. It snaps to the nearest screen edge when enabled. Long press it to open PixiePop settings.
5. Single tap the character to launch the installed official ChatGPT Android app through its normal launcher activity. If absent, PixiePop opens the ChatGPT Play Store listing (or its web listing). Single tap waits 330 ms so a second/third tap can be recognized.
6. Configure double and triple taps independently under **Thao tác chạm**. Defaults are happy reaction and next character. Options: happy reaction, next character, open a selected installed app, toggle flashlight, screenshot, or start/stop screen recording. To use instant screenshots, tap **Cấp quyền chụp màn hình** and enable **PixiePop chụp màn hình** in Android Accessibility settings once. A drag or long press cancels any unfinished tap sequence.
7. Use **Dừng nhân vật nổi** or the notification **Dừng** action to remove the overlay and stop the service.

If the floating character does not appear after tapping **Bắt đầu nhân vật nổi**, the app now shows a specific startup error instead of silently reverting to the start button. Check the on-screen message and Android's **Display over other apps** setting. The service also writes the full exception to Logcat under `GhostOverlayService` for diagnosis. The app starts its foreground service before requesting optional notification permission; notification denial does not block the overlay. Real-device verification on a Galaxy Z Fold5 is still required.

V1.0.2 uses the service context for the overlay window to avoid window-token mismatches on vendor Android builds. It also saves a short local crash reason and shows it under **Nhân vật nổi** when the app is reopened. If Android still closes PixiePop, send a screenshot of that reason; it is stored only on the device and is never uploaded.

PixiePop does **not** start ChatGPT Voice, automate accessibility actions, use undocumented deep links, listen to speech, or read other apps. The app requests no Internet permission. The default launcher package is `com.openai.chatgpt`; package visibility for installed launcher apps is declared in `<queries>`.

## Optional gesture actions

**Mở ứng dụng** launches the installed app chosen in settings. If none is chosen, it launches ChatGPT as before. The flashlight action asks for the Android camera permission on first use and reports when the device has no flash.

**Chụp màn hình** uses Android's documented `AccessibilityService.takeScreenshot` API to capture the currently visible display without the app/screen picker after the user explicitly enables the screenshot service. The service subscribes to no accessibility events, reads no UI hierarchy, and performs no gestures. Android may reject screenshots of protected content. Screenshots are saved to `Pictures/PixiePop` as PNG. On Android versions that restrict accessibility for sideloaded APKs, open PixiePop's app info menu and choose **Allow restricted settings** before enabling this service.

**Quay màn hình** still uses MediaProjection. Android displays its consent dialog each time a recording begins and may offer to share one app or the whole display. Videos are saved to `Movies/PixiePop` as MP4. A recording can be stopped by repeating its assigned gesture or tapping **Dừng** in its foreground notification. Video has no microphone or internal audio.

## Animation and assets

`app/src/main/res/drawable-nodpi/ic_pixiepop.png` is the new launcher icon adapted from the supplied PixiePop image. `app/src/main/assets/ghostgirl_atlas.png` is transparent **prototype art** inspired by the supplied visual references. Six `_sheet.png` assets are transparent cutouts adapted from the attached character concept sheets: Mimi (lavender cat hoodie), Sunny (orange hair and headset), Ruby (red jacket), Mèo Cam (tabby cat), Yuki (white cat hoodie), and Mai Mai (pink-haired cat maid). These are **reference-derived prototype pose sheets**, not original production sprite atlases or frame-by-frame animations. Some edges may need manual pixel cleanup. Only use/distribute these art assets if you hold the necessary rights to the supplied references.

`GhostSpriteView` chooses a matching pose crop for each character and applies low-cost motion to it. Happy is the default double tap response, walking reacts to drag, reacting to long press or character change, and sleeping starts after one idle minute. All seven moods can be previewed in settings. Talking and sad are preview states; there is no ChatGPT state integration.

To replace the art, provide a licensed transparent PNG and update the corresponding asset name and crop coordinates in `GhostCharacter.bounds` (or `GhostAtlas.bounds` for the original PixiePop). The overlay fits each crop within a square view. Bitmap sampling disables filtering for sharp pixels.

## Service and foldable behavior

The overlay is a user-started foreground service with the Android `specialUse` service type, a persistent notification and a stop action. It uses the documented overlay permission flow. The window does not take keyboard focus. When the screen turns off, animation callbacks stop; idle and sleeping states update at a lower rate. The service is `START_NOT_STICKY` and does not auto-start after reboot.

On rotation and display changes, the service reads current window metrics and safe insets, then clamps the saved position into the new bounds. This is intended to handle Fold5 inner and cover displays. Screen-edge snapping and settings have pure unit tests. Publishing to Google Play may require a policy declaration for `SYSTEM_ALERT_WINDOW` and `FOREGROUND_SERVICE_SPECIAL_USE`; this debug build is for direct installation and testing.

## Tests

```bash
./gradlew testDebugUnitTest
```

The tests cover settings limits, overlay bounds/snap logic on narrow folded dimensions, atlas and character crop mapping, character cycling, gesture timing/cancellation, persisted action mapping, and video size limits. Manual device checks still needed: screenshot service enable/disable, visible display and protected-content screenshots, screenshot/video files, MediaProjection approval/denial for recordings, permission grant/revoke, starting/stopping the overlay, single/double/triple tap with each assigned action, camera permission/flash availability, recording stop, long press settings, drag and edge snap, notification stop, screen off battery behavior, and unfolding/rotation on a Galaxy Z Fold5 with Android 16.

The cloud build runs `testDebugUnitTest`, `assembleDebug`, `lintDebug`, `apksigner verify`, and `zipalign -c`. No physical Galaxy Z Fold5 was available for installation testing. The local Android emulator cannot start because this cloud host has no KVM acceleration, so the screenshot permission flow still needs a real-device check.
