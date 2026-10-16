# GhostGirl Android V1

Native Kotlin + Jetpack Compose Android project for a floating pixel-art companion. The overlay uses `WindowManager.TYPE_APPLICATION_OVERLAY`; the settings screen uses Compose. It does not need an OpenAI API key and does not connect to any API.

[Download GhostGirl Android V1.0.1 debug APK](https://raw.githubusercontent.com/Nobitakuns/Dzjmaster.com/new-project/downloads/GhostGirl-Android-V1.0.1-debug.apk) (overlay startup fix). SHA-256: `f1071d7a6ce98062bf842d52b78ed3bf5456389f6fc3cdbb3defd23056a079c7`. The APK has version code 2 and installs over V1.

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
5. Single tap the character to launch the installed official ChatGPT Android app through its normal launcher activity. If absent, GhostGirl opens the ChatGPT Play Store listing (or its web listing).
6. Use **Dừng nhân vật nổi** or the notification **Dừng** action to remove the overlay and stop the service.

If the floating character does not appear after tapping **Bắt đầu nhân vật nổi**, the app now shows a specific startup error instead of silently reverting to the start button. Check the on-screen message and Android's **Display over other apps** setting. The service also writes the full exception to Logcat under `GhostOverlayService` for diagnosis. The app starts its foreground service before requesting optional notification permission; notification denial does not block the overlay. Real-device verification on a Galaxy Z Fold5 is still required.

GhostGirl does **not** start ChatGPT Voice, automate accessibility actions, use undocumented deep links, listen to speech, or read other apps. The app requests no Internet permission. The launcher package is `com.openai.chatgpt`; package visibility is declared in `<queries>`.

## Animation and assets

`app/src/main/assets/ghostgirl_atlas.png` is a transparent **prototype art** atlas inspired by the supplied visual references. It is not claimed to be the final original sprite source. The 4 × 2 grid contains seven poses: idle, happy, sad, sleeping, walking, talking and reacting; the last cell is empty. `GhostSpriteView` selects cells and applies low-cost motion to animate each pose. Happy reacts to tap, walking to drag, reacting to long press, and sleeping after one idle minute. All seven can be previewed from settings. Talking and sad are preview states in V1; there is no ChatGPT state integration.

To replace the art, provide a licensed transparent PNG with the same 4 × 2 pose order, or update `GhostAtlas.bounds` and the drawable source. The overlay is a square view; use transparent padding within each cell so every pose stays centered. Bitmap sampling disables filtering for sharp pixels.

## Service and foldable behavior

The overlay is a user-started foreground service with the Android `specialUse` service type, a persistent notification and a stop action. It uses the documented overlay permission flow. The window does not take keyboard focus. When the screen turns off, animation callbacks stop; idle and sleeping states update at a lower rate. The service is `START_NOT_STICKY` and does not auto-start after reboot.

On rotation and display changes, the service reads current window metrics and safe insets, then clamps the saved position into the new bounds. This is intended to handle Fold5 inner and cover displays. Screen-edge snapping and settings have pure unit tests. Publishing to Google Play may require a policy declaration for `SYSTEM_ALERT_WINDOW` and `FOREGROUND_SERVICE_SPECIAL_USE`; this debug build is for direct installation and testing.

## Tests

```bash
./gradlew testDebugUnitTest
```

The tests cover settings limits, overlay bounds/snap logic on narrow folded dimensions, and atlas cell mapping. Manual device checks still needed: permission grant/revoke, starting/stopping the service, single tap to ChatGPT/Play Store, long press settings, drag and edge snap, notification stop, changing size/opacity/speed, screen off battery behavior, and unfolding/rotation on a Galaxy Z Fold5 with Android 16.

Build verification in the cloud environment: `testDebugUnitTest` passed 7 tests, `assembleDebug` succeeded, Android `lintDebug` found no issues, and `apksigner verify` plus `zipalign -c` passed. No physical Android device was available for installation testing.
