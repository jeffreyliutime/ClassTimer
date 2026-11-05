# ClassTimer｜课堂计时器

一款面向课堂、培训和演讲场景的轻量计时工具。讲师在控制台设置计时，学员端通过独立悬浮窗口查看时间。

## 平台版本

| 平台 | 分发包 | 运行环境 | 发布状态 |
|---|---|---|---|
| Windows | ClassTimer Lite v1.7 ZIP | Windows 10/11；.NET Framework 4.8 | 
|
| macOS | ClassTimer v1.2 Apple Silicon ZIP | Apple Silicon；macOS 27 |  |

> 当前仓库正在建立项目说明与发布结构。GitHub 连接可以提交文本文件，但当前可用的上传接口不能直接传输 ZIP/EXE/App 等二进制文件，因此下载包尚未出现在仓库中。不会放置失效的下载链接，也不会把文档或早期原型冒充为完整源代码。

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

Windows 分发包发布后，下载 ZIP 并解压，双击运行 `ClassTimerLite.exe`。无需安装程序；运行环境为 .NET Framework 4.8。首次运行时，Windows SmartScreen 可能提示无法识别发布者，因为当前分发包没有经过 Microsoft 认可的发布者代码签名。这不等于检测到恶意软件。请只从可信来源下载，不要为了运行程序而关闭 Windows 安全保护。

## macOS 安装

macOS 分发包发布后，下载 ZIP 并解压，将 `ClassTimer.app` 拖入「应用程序」文件夹后启动。当前包为 Apple Silicon 原生 ARM64 构建。该构建未使用 Apple Developer ID 签名和 Apple 公证；首次打开时 macOS 可能显示安全提示。请确认下载来源可信，再按 macOS 提供的方式允许打开。不要关闭 Gatekeeper 或系统安全保护。

## 版本与兼容性说明

### Windows v1.7
- 六段计时
- 不足一小时显示 `MM:SS`，达到一小时显示 `HH:MM:SS`
- .NET Framework 4.8
- 轻量原生 Windows 程序，不包含 Chromium

### macOS v1.2（Apple Silicon）
- 原生 ARM64 构建
- 最多六段计时，支持时／分／秒
- 倒计时、正计时和时钟模式
- 多屏显示、学员端尺寸、主题与提醒文字
- 未进行 Apple Developer ID 签名或公证
- 外接投影、Keynote／PowerPoint 全屏覆盖行为仍需在实际授课设备验收

**版本注意：** macOS ZIP 内附的安装说明文件标题仍标注 v1.0；仓库以交付压缩包文件名 v1.2 作为本次分发包标识，未擅自改写包内原始文件。

## 仓库结构

- `README.md` — 项目说明与安装指南
- `docs/RELEASES.md` — 分发版本记录与校验值
- `downloads/` — 计划存放 Windows 与 macOS 分发包

完整、可复现的当前版本构建源码尚未整理进仓库。

## 项目

https://github.com/jeffreyliutime/ClassTimer
