#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
package_root="$repo_root/macos/PixiePop"
output_root="$repo_root/dist"
build_root="${RUNNER_TEMP:-/tmp}/pixiepop-mac-build"
version="0.1.0"
app_path="$output_root/PixiePop.app"
dmg_path="$output_root/PixiePop-macOS-arm64-$version.dmg"

mkdir -p "$output_root"
swift build --package-path "$package_root" --configuration release --arch arm64 \
    --scratch-path "$build_root"
binary_dir="$(swift build --package-path "$package_root" --configuration release \
    --arch arm64 --scratch-path "$build_root" --show-bin-path)"
test "$(lipo -archs "$binary_dir/PixiePopMac")" = "arm64"

mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources/Sprites"
cp "$binary_dir/PixiePopMac" "$app_path/Contents/MacOS/PixiePopMac"
cp "$package_root/Info.plist" "$app_path/Contents/Info.plist"
cp "$repo_root/app/src/main/assets/"*.png "$app_path/Contents/Resources/Sprites/"

icon_source="$repo_root/app/src/main/res/drawable-nodpi/ic_pixiepop.png"
iconset="$build_root/AppIcon.iconset"
mkdir -p "$iconset"
for points in 16 32 128 256 512; do
    sips -z "$points" "$points" "$icon_source" \
        --out "$iconset/icon_${points}x${points}.png" >/dev/null
    doubled=$((points * 2))
    sips -z "$doubled" "$doubled" "$icon_source" \
        --out "$iconset/icon_${points}x${points}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o "$app_path/Contents/Resources/AppIcon.icns"

codesign --force --deep --sign - --timestamp=none "$app_path"
codesign --verify --deep --strict --verbose=2 "$app_path"

stage="$build_root/dmg-stage"
mkdir -p "$stage"
cp -R "$app_path" "$stage/"
ln -s /Applications "$stage/Applications"
hdiutil create -volname PixiePop -srcfolder "$stage" -ov -format UDZO "$dmg_path"
hdiutil verify "$dmg_path"
shasum -a 256 "$dmg_path" | tee "$dmg_path.sha256"
file "$dmg_path"
