# ClassTimer｜课堂计时器

一款面向课堂、培训和演讲场景的轻量计时工具。讲师在控制台设置计时，学员端通过独立悬浮窗口查看时间。

**本仓库当前提供 Windows 与 macOS 的可运行分发包。** 完整、可复现的最新版本构建源码尚未整理进仓库；这里不会把早期原型或界面参考文件冒充为当前正式版源码。

## 下载

| 平台 | 版本 | 下载 | 适用环境 |
|---|---:|---|---|
| Windows | 1.7 | [ClassTimerLite_Windows_v1.7.zip](downloads/ClassTimerLite_Windows_v1.7.zip) | Windows 10 / 11；需要 .NET Framework 4.8 |
| macOS | 1.2 | [ClassTimer_Mac_1.2_AppleSilicon.zip](downloads/ClassTimer_Mac_1.2_AppleSilicon.zip) | Apple Silicon（M 系列）；macOS 27.0 或更高版本 |

## 功能概览

- 讲师控制台与学员悬浮计时窗口
- 最多六个独立计时段
- 每段可设置小时、分钟和秒
- 倒计时、正计时和当前时钟模式
- 开始、暂停／继续、重置与增减一分钟
- 多段计时与循环
- 选择学员端显示屏幕
- 学员端窗口尺寸与背景主题设置
- 提醒文字显示

具体功能以对应平台的版本为准。

## Windows 安装

1. 下载 Windows ZIP 并解压。
2. 双击运行 `ClassTimerLite.exe`。
3. 在讲师控制台选择显示屏幕并设置计时段。

这是免安装的轻量 Windows 程序。当前包使用 .NET Framework 4.8，不包含 Chromium。首次运行时，Windows SmartScreen 可能提示无法识别发布者；这是因为当前分发包没有经过 Microsoft 认可的发布者代码签名，并不等同于检测到恶意软件。请只从你信任的来源下载，不要为了运行程序而关闭 Windows 安全保护。

## macOS 安装

1. 下载 macOS ZIP 并解压。
2. 将 `ClassTimer.app` 拖入「应用程序」文件夹。
3. 双击启动。

当前 macOS 包为 Apple Silicon 原生 ARM64 构建，最低系统版本为 macOS 27.0。该版本采用本地临时签名，尚未使用 Apple Developer ID 签名和 Apple 公证；首次打开时 macOS 可能显示安全提示。请先确认下载来源可信，再按 macOS 提供的方式允许打开。不要关闭 Gatekeeper 或系统安全保护。

## 已知限制

- Windows 与 macOS 的分发包均未使用面向公众发行的正式开发者证书签名。
- macOS 版本目前仅提供 Apple Silicon 构建，不包含 Intel 版本。
- 投影、全屏演示软件覆盖及多屏行为仍应在实际授课设备上验证。
- 当前仓库提供的是可运行分发包，不代表已公开完整构建源码。

## 版本记录

### Windows v1.7
- 六段计时
- 时间显示格式优化：不足一小时显示 `MM:SS`，达到一小时显示 `HH:MM:SS`

### macOS v1.2
- Apple Silicon 原生 ARM64 构建
- 最多六段计时，支持时／分／秒
- 支持倒计时、正计时和时钟模式
- 支持多屏显示、学员端尺寸、主题与提醒文字

---

**项目名称：** ClassTimer  
**仓库：** https://github.com/jeffreyliutime/ClassTimer
