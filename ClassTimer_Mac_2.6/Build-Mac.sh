#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v xcodebuild >/dev/null || ! xcodebuild -version >/dev/null 2>&1; then
    printf '%s\n' '请先在 Apple Silicon Mac 上安装并选中含 macOS 15 SDK 的 Xcode。' >&2
    exit 1
fi

build_dir="$PWD/build"
mkdir -p "$build_dir"
xcrun swiftc -swift-version 6 ClassTimer/TimerCore.swift Tests/TimerCoreChecks.swift -o "$build_dir/TimerCoreChecks"
"$build_dir/TimerCoreChecks"

xcodebuild -project ClassTimer.xcodeproj -scheme ClassTimer -configuration Release \
    -destination 'generic/platform=macOS' -derivedDataPath "$build_dir/xcode" build
app="$build_dir/xcode/Build/Products/Release/ClassTimer.app"
codesign --verify --strict "$app"
/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$app/Contents/Info.plist" | grep -qx '2.6'
ditto -c -k --sequesterRsrc --keepParent "$app" "$build_dir/ClassTimer_Mac_2.6_AppleSilicon.zip"
printf '%s\n' "$build_dir/ClassTimer_Mac_2.6_AppleSilicon.zip"
