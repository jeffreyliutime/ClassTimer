<div align="center">

# ClassTimer

**A floating classroom timer for Windows and macOS**  
**面向课堂、培训、工作坊与演讲的悬浮计时器**

讲师在自己的屏幕上控制计时，学员在投影或独立显示屏上看到始终置顶的计时窗口。

![ClassTimer interface preview](docs/preview.svg)

[Windows v1.7 安装包：发布文件正在整理] · [项目问题与反馈](https://github.com/jeffreyliutime/ClassTimer/issues)

</div>

---

## What it does｜它解决什么问题

ClassTimer separates the instructor's controls from the timer shown to the audience.

- **Instructor console｜讲师控制台**：设置计时段、开始／暂停／重置、调整时间与控制显示窗口。
- **Floating student display｜学员悬浮窗**：独立显示计时数字，可用于投影、扩展屏和课堂大屏。
- **Multi-segment timing｜多段计时**：最多六段，每段独立设置时长。
- **Flexible modes｜多种模式**：倒计时、正计时与当前时钟。
- **Presentation-friendly｜适合演示场景**：可选择显示屏、调整窗口尺寸、切换背景主题并显示提醒文字。

## Downloads｜下载

| Platform | Version | Package | Compatibility |
|---|---|---|---|
| Windows | **ClassTimer Lite 1.7** | Package publication pending | Windows 10 / 11 · .NET Framework 4.8 |
| macOS | **ClassTimer 1.2** | Package publication pending | Apple Silicon (M1 and later) · macOS 27.0+ |

> macOS v1.2 has been built as a native ARM64 app. Its ZIP package is not yet attached to this public repository; a download link will be added when the binary is published. No placeholder or broken download link is used.

## Windows｜安装与使用

1. Download the Windows v1.7 ZIP from the repository Releases page once the package is published.
2. Extract the ZIP file.
3. Double-click `ClassTimerLite.exe`.
4. Set the number and duration of segments, select the display, then start the timer.

**Runtime:** .NET Framework 4.8. The package does not include Chromium and does not require an installer.

**Windows security notice:** The current package is not signed with a publicly trusted code-signing certificate. Windows SmartScreen may therefore show an unfamiliar-publisher warning. This warning does not by itself mean malware has been detected. Download only from a source you trust; do not disable Windows security protections to run the app.

## macOS｜安装与使用

The macOS v1.2 build targets Apple Silicon and macOS 27.0 or later.

1. Download and extract the macOS ZIP once it is published here.
2. Move `ClassTimer.app` into the Applications folder.
3. Open ClassTimer and configure the instructor and student windows.

**macOS security notice:** The current build has not been signed with an Apple Developer ID certificate or notarized by Apple. macOS may show a first-launch security prompt. Verify the download source and use macOS's normal per-app approval process if appropriate. Do not disable Gatekeeper.

## Features｜功能清单

- Up to 6 timer segments｜最多六段计时
- Per-segment hours, minutes and seconds｜每段独立设置时、分、秒
- Countdown / count-up / clock｜倒计时、正计时、时钟
- Start, pause, resume and reset｜开始、暂停、继续、重置
- Quick adjustment by one minute｜加减一分钟
- Optional loop mode｜循环计时
- Selectable display screen｜选择投影／显示屏
- Floating student window with size and theme options｜学员悬浮窗尺寸与主题设置
- Reminder text｜提醒文字

Features and window behavior can differ slightly by operating system.

## Version notes｜版本说明

### Windows · v1.7
- Windows 10 / 11
- .NET Framework 4.8
- Lightweight native Windows application; no Chromium runtime
- Time format: `MM:SS` below one hour and `HH:MM:SS` at one hour or above

### macOS · v1.2
- Native Apple Silicon ARM64 build
- Built with macOS 27.0 SDK
- Bundle identifier: `com.harmonizedintelligence.classtimer`
- Minimum system version: macOS 27.0
- Not yet notarized by Apple
- External display, Keynote and PowerPoint full-screen overlay behavior should be verified on the actual teaching setup

## Privacy｜隐私

The macOS app does not require an account or login and is designed to run locally. It does not request camera, microphone, screen-recording or accessibility permissions for its timer display. The Windows app also runs as a local desktop utility.

## Repository status｜仓库状态

This repository currently contains the project overview and interface preview. The Windows v1.7 and macOS v1.2 binaries have been built and checked locally, but their downloadable release assets have not yet been attached to GitHub. The complete, reproducible source projects for the current Windows and macOS releases have not yet been published here.

The project license has not yet been specified. Until a license is added, no open-source reuse or redistribution rights should be assumed.

## Feedback

Please use [GitHub Issues](https://github.com/jeffreyliutime/ClassTimer/issues) for bug reports and feature suggestions.
