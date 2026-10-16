# PixiePop for macOS

Native AppKit floating companion for macOS 13 or newer on Apple Silicon. It uses the seven replaceable PNG character sheets from the Android project. The sheets are prototype art adapted from the supplied references, not finished original frame-by-frame sprites.

## Install

Download `PixiePop-macOS-arm64-0.1.0.dmg` from the [Mac release](https://github.com/Nobitakuns/Dzjmaster.com/releases/tag/pixiepop-mac-v0.1.0). Open the DMG and drag **PixiePop** into **Applications**. On first launch, macOS may warn because the build is ad-hoc signed and has no Apple notarization. If blocked, open **System Settings → Privacy & Security → Open Anyway** for PixiePop. Do not disable Gatekeeper globally.

The menu bar **✦ PixiePop** item opens settings, starts or stops the floating character, checks for updates, and quits. Drag the character to move it. One click opens the installed ChatGPT Mac app if available, or `chatgpt.com`. Double and triple clicks use the selected actions. Long press opens settings. Settings persist across version updates under bundle ID `com.pixiepop.companion`.

The optional screenshot action saves a PNG in `~/Pictures/PixiePop` using macOS `screencapture`. macOS may ask for **Screen Recording** permission on first use. The prototype does not record video or control another app. The foreground companion does not need an OpenAI API key.

## Updating

PixiePop checks the repository's Mac release list on launch and from **Kiểm tra cập nhật**. If a newer `pixiepop-mac-v*` release exists, it offers the DMG download. Quit the old app, open the new DMG, and drag PixiePop into Applications to replace it. Character, size, gesture, and position settings remain in macOS UserDefaults. This is a user-confirmed update, not a silent installer.

## Build

On a Mac with Xcode command line tools:

```bash
swift test --package-path macos/PixiePop
bash macos/PixiePop/scripts/package.sh
```

The packaging script compiles `arm64`, verifies the architecture and ad-hoc code signature, and runs `hdiutil verify`. The release workflow builds the DMG on GitHub's macOS runner. Real M1 operation, Screen Recording permission, clicking and dragging, and update behavior still require a physical Mac test.
