import AppKit
import Combine
import SwiftUI

struct DisplayOption: Identifiable {
    let id: UInt32
    let name: String
}

extension NSScreen {
    var classTimerDisplayID: UInt32? {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }
}

enum DisplaySize: String, CaseIterable, Identifiable {
    case small = "小", medium = "中", large = "大"
    var id: Self { self }
    var panelSize: CGSize {
        switch self {
        case .small: CGSize(width: 340, height: 150)
        case .medium: CGSize(width: 620, height: 270)
        case .large: CGSize(width: 880, height: 355)
        }
    }
}

enum DisplayTheme: String, CaseIterable, Identifiable {
    case green = "绿色", black = "黑色", white = "白色", blue = "蓝色"
    var id: Self { self }
    var background: Color {
        switch self {
        case .green: Color(red: 0.05, green: 0.28, blue: 0.19)
        case .black: .black
        case .white: .white
        case .blue: Color(red: 0.06, green: 0.21, blue: 0.39)
        }
    }
}

@MainActor
final class TimerModel: ObservableObject {
    @Published private(set) var core = TimerCore()
    @Published private(set) var wallClock = Date()
    @Published var draftSegments = [TimerSegment()]
    @Published var displayID: UInt32 = NSScreen.main?.classTimerDisplayID ?? 0
    @Published var displays: [DisplayOption] = []
    @Published var displaySize = DisplaySize.small
    @Published var theme = DisplayTheme.green
    @Published var message = ""
    @Published var overlayVisible = true
    @Published private(set) var fullscreen = false
    @Published private(set) var presets: [TimerPreset]
    @Published var presetSelection = ""
    @Published var presetName = ""
    @Published var presetStatus = ""
    @Published var alarmSelection = Date()
    @Published var alarmSecond = Calendar.current.component(.second, from: Date())

    private let presetURL: URL
    private var activePresetID = ""
    private var previousSegmentIndex: Int?
    private var ticker: Timer?
    private let overlay = OverlayPanelController()

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let adjacent = Bundle.main.bundleURL.deletingLastPathComponent()
        let candidates = [
            support.appendingPathComponent("ClassTimer/timer-presets.json"),
            adjacent.appendingPathComponent("ClassTimer_Data/timer-presets.json"),
            adjacent.appendingPathComponent("ClassTimer/timer-presets.json"),
            adjacent.appendingPathComponent("timer-presets.json")
        ]
        let fm = FileManager.default
        presetURL = candidates.first { fm.fileExists(atPath: $0.path) } ?? candidates[0]
        if let data = try? Data(contentsOf: presetURL) {
            do {
                presets = try JSONDecoder().decode([TimerPreset].self, from: data)
            } catch {
                presets = []
                presetStatus = "已有方案文件无法读取，已保留原文件。"
            }
        } else {
            presets = []
        }
        refreshDisplays()
    }

    var running: Bool { core.state == .running }
    var time: String { core.formattedTime(now: wallClock) }
    var stageName: String { core.mode == .countdown ? core.current.name : "" }
    var flashOn: Bool { core.alertActive && Int(wallClock.timeIntervalSinceReferenceDate * 2) % 2 == 0 }
    var status: String {
        if core.alertActive { return "时间到 · 请停止提醒" }
        if core.mode == .countdown {
            let state = switch core.state {
            case .ready: "待开始"
            case .running: "正在计时"
            case .paused: "已暂停"
            case .finished: "时间到"
            }
            return "\(state) · 第 \(core.index + 1) 段"
        }
        if core.mode == .stopwatch { return running ? "秒表运行中" : core.state == .paused ? "秒表已暂停" : "秒表待开始" }
        if core.mode == .clock { return "实时时钟" }
        if let alarm = core.alarmDate { return "闹钟已设置 · \(alarm.formatted(date: .omitted, time: .standard))" }
        return "尚未设置闹钟"
    }

    func launch() {
        refreshDisplays()
        if overlayVisible { overlay.show(self) }
        if ticker == nil {
            let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in self?.tick() }
            }
            ticker = timer
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func selectMode(_ mode: TimerMode) {
        core.changeMode(mode)
        if mode == .alarm && core.alarmDate == nil {
            alarmSelection = Date()
            alarmSecond = Calendar.current.component(.second, from: alarmSelection)
        }
    }

    func start() { core.start(at: ProcessInfo.processInfo.systemUptime) }
    func togglePause() {
        if running {
            core.pause(at: ProcessInfo.processInfo.systemUptime, now: Date())
        } else if core.state == .paused {
            start()
        }
    }
    func reset() { core.reset() }
    func toggleLoop() { core.loop.toggle() }
    func stopAlert() { core.stopAlert() }

    func adjust(_ delta: Int) {
        core.adjustMinute(delta, at: ProcessInfo.processInfo.systemUptime, now: Date())
    }

    func advance() {
        core.advance(at: ProcessInfo.processInfo.systemUptime, expectedIndex: previousSegmentIndex ?? core.index)
        previousSegmentIndex = nil
    }

    func markAdvancePress(_ pressed: Bool) {
        if pressed { previousSegmentIndex = core.index }
        else {
            Task { @MainActor [weak self] in self?.previousSegmentIndex = nil }
        }
    }

    func addSegment() {
        draftSegments.append(TimerSegment(minutes: 5))
        applySegments()
    }

    func removeSegment(_ index: Int) {
        guard draftSegments.count > 1, draftSegments.indices.contains(index) else { return }
        draftSegments.remove(at: index)
        applySegments()
    }

    func applySegments() { core.applySegments(draftSegments) }

    func armAlarm() {
        let calendar = Calendar.current
        var time = calendar.dateComponents([.hour, .minute], from: alarmSelection)
        time.second = alarmSecond
        if let date = calendar.nextDate(after: Date(), matching: time, matchingPolicy: .nextTime) {
            core.armAlarm(date)
        }
    }

    func cancelAlarm() { core.cancelAlarm() }

    func refreshDisplays() {
        displays = NSScreen.screens.compactMap { screen in
            screen.classTimerDisplayID.map { DisplayOption(id: $0, name: screen.localizedName) }
        }
        if !displays.contains(where: { $0.id == displayID }) { displayID = displays.first?.id ?? 0 }
    }

    func moveOverlay() { overlay.place(self) }

    func showOverlay(_ visible: Bool) {
        overlayVisible = visible
        if visible { overlay.show(self) }
        else {
            if fullscreen { setFullscreen(false) }
            overlay.hide()
        }
    }

    func chooseSize(_ size: DisplaySize) {
        displaySize = size
        setFullscreen(false)
    }

    func setFullscreen(_ enabled: Bool) {
        fullscreen = enabled
        if enabled { showOverlay(true) }
        else { overlay.place(self) }
    }

    func loadPreset() {
        guard let preset = presets.first(where: { $0.id == presetSelection }), !preset.segments.isEmpty else {
            presetStatus = "请先选择方案。"
            return
        }
        activePresetID = preset.id
        presetName = preset.name
        draftSegments = preset.segments
        applySegments()
        presetStatus = "当前方案已加载。"
    }

    func savePreset(asNew: Bool) {
        let name = presetName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { presetStatus = "请填写方案名称。"; return }
        var updated = presets
        let id: String
        if asNew {
            let preset = TimerPreset(name: name, segments: draftSegments)
            id = preset.id
            updated.append(preset)
        } else {
            guard let index = updated.firstIndex(where: { $0.id == activePresetID }) else {
                presetStatus = "请先加载方案，或使用另存为。"
                return
            }
            id = activePresetID
            updated[index].name = name
            updated[index].segments = draftSegments
        }
        guard !updated.contains(where: { $0.id != id && $0.name == name }) else {
            presetStatus = "方案名称已存在。"
            return
        }
        guard persist(updated) else { return }
        activePresetID = id
        presetSelection = id
        presetStatus = "方案已保存。"
    }

    func deleteSelectedPreset() {
        let id = presetSelection
        guard !id.isEmpty, persist(presets.filter { $0.id != id }) else { return }
        presetSelection = ""
        if activePresetID == id { activePresetID = ""; presetName = "" }
        presetStatus = "方案已删除。"
    }

    private func persist(_ updated: [TimerPreset]) -> Bool {
        do {
            let fm = FileManager.default
            if fm.fileExists(atPath: presetURL.path) {
                let original = try Data(contentsOf: presetURL)
                _ = try JSONDecoder().decode([TimerPreset].self, from: original)
            }
            try fm.createDirectory(at: presetURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(updated).write(to: presetURL, options: .atomic)
            presets = updated
            return true
        } catch {
            presetStatus = "保存失败，原方案文件已保留。"
            return false
        }
    }

    private func tick() {
        let now = Date()
        let wallClockNeeded = core.mode == .clock || core.mode == .alarm || core.alertActive
        if wallClockNeeded && Int(now.timeIntervalSinceReferenceDate * 2) != Int(wallClock.timeIntervalSinceReferenceDate * 2) {
            wallClock = now
        }
        var updated = core
        updated.tick(at: ProcessInfo.processInfo.systemUptime, now: now)
        if updated != core { core = updated }
    }
}

@MainActor
final class OverlayPanelController {
    private var panel: NSPanel?

    func show(_ model: TimerModel) {
        if panel == nil {
            let newPanel = NSPanel(contentRect: CGRect(origin: .zero, size: model.displaySize.panelSize),
                                   styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            newPanel.level = .floating
            newPanel.collectionBehavior = [.canJoinAllApplications, .canJoinAllSpaces, .stationary, .ignoresCycle]
            newPanel.isFloatingPanel = true
            newPanel.hidesOnDeactivate = false
            newPanel.isMovableByWindowBackground = true
            newPanel.contentView = NSHostingView(rootView: LearnerView(model: model))
            panel = newPanel
        }
        place(model)
        panel?.orderFrontRegardless()
    }

    func hide() { panel?.orderOut(nil) }

    func place(_ model: TimerModel) {
        guard let panel,
              let screen = NSScreen.screens.first(where: { $0.classTimerDisplayID == model.displayID }) ?? NSScreen.main else { return }
        if model.fullscreen {
            panel.level = .screenSaver
            panel.isMovableByWindowBackground = false
            panel.setFrame(screen.frame, display: true)
        } else {
            let frame = screen.visibleFrame
            let preferred = model.displaySize.panelSize
            let size = CGSize(width: min(preferred.width, frame.width), height: min(preferred.height, frame.height))
            panel.level = .floating
            panel.isMovableByWindowBackground = true
            panel.setFrame(CGRect(x: max(frame.minX, frame.maxX - size.width - 24),
                                  y: max(frame.minY, frame.maxY - size.height - 24),
                                  width: size.width, height: size.height), display: true)
        }
    }
}

struct LearnerView: View {
    @ObservedObject var model: TimerModel

    var body: some View {
        GeometryReader { geometry in
            let digitSize = min(geometry.size.height * 0.39, geometry.size.width * 0.17)
            let textColor: Color = model.theme == .white ? .black : .white
            VStack(spacing: 2) {
                if !model.stageName.isEmpty {
                    Text(model.stageName).font(.system(size: digitSize * 0.5, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.3)
                }
                Text(model.time).font(.system(size: digitSize, weight: .bold, design: .rounded).monospacedDigit())
                    .lineLimit(1).minimumScaleFactor(0.3)
                if !model.message.isEmpty {
                    Text(model.message).font(.system(size: digitSize * 0.5)).lineLimit(1).minimumScaleFactor(0.3)
                }
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(model.flashOn ? .white : textColor)
            .background(model.flashOn ? Color.red : model.theme.background)
            .overlay(alignment: .topTrailing) {
                Button(model.fullscreen ? "退出全屏 Esc" : "关闭学员计时窗口") {
                    if model.fullscreen { model.setFullscreen(false) }
                    else { model.showOverlay(false) }
                }
                .font(.caption)
                .padding(6)
                .opacity(model.fullscreen ? 1 : 0.75)
            }
        }
        .onTapGesture(count: 2) { if model.fullscreen { model.setFullscreen(false) } }
        .onExitCommand { if model.fullscreen { model.setFullscreen(false) } }
    }
}

struct FloatingLecturerWindow: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { NSView() }
    func updateNSView(_ view: NSView, context: Context) {
        DispatchQueue.main.async { [weak view] in view?.window?.level = .floating }
    }
}

struct LecturerView: View {
    @ObservedObject var model: TimerModel
    @State private var messageDraft = ""
    @State private var confirmDelete = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(model.time).font(.system(size: 48, weight: .bold, design: .rounded).monospacedDigit())
                        Text(model.status).foregroundStyle(model.flashOn ? Color.red : .secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    VStack(alignment: .trailing, spacing: 8) {
                        HStack {
                            Button("开始") { model.start() }.buttonStyle(.borderedProminent)
                                .disabled(model.running || model.core.mode == .clock || model.core.mode == .alarm)
                            Button(model.core.state == .paused ? "继续" : "暂停") { model.togglePause() }
                                .disabled(!model.running && model.core.state != .paused)
                            Button("重置") { model.reset() }
                                .disabled(model.core.mode == .clock || model.core.mode == .alarm)
                            if model.core.mode == .countdown {
                                Button(model.core.loop ? "循环 · 开" : "循环 · 关") { model.toggleLoop() }
                            }
                        }
                        if model.core.mode == .countdown {
                            HStack {
                                Button("＋1分钟") { model.adjust(1) }
                                Button("－1分钟") { model.adjust(-1) }
                                if model.core.segments.count > 1 {
                                    Button("进入下一段", action: model.advance)
                                        .buttonStyle(NextSegmentButtonStyle(onPress: model.markAdvancePress))
                                        .disabled(!model.core.canAdvance)
                                }
                            }
                        }
                    }
                }

                HStack {
                    Picker("计时模式", selection: Binding(get: { model.core.mode }, set: model.selectMode)) {
                        ForEach(TimerMode.allCases) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)
                    Picker("学员窗口配色", selection: $model.theme) {
                        ForEach(DisplayTheme.allCases) { Text($0.rawValue).tag($0) }
                    }.labelsHidden().frame(width: 100)
                }

                if model.core.alertActive {
                    Button("停止提醒", action: model.stopAlert)
                }
                if model.core.mode == .alarm {
                    GroupBox("一次性闹钟") {
                        HStack {
                            DatePicker("时间", selection: $model.alarmSelection, displayedComponents: .hourAndMinute)
                            Stepper("秒 \(model.alarmSecond)", value: $model.alarmSecond, in: 0...59)
                            Button("启动闹钟", action: model.armAlarm)
                            Button("取消闹钟", action: model.cancelAlarm).disabled(model.core.alarmDate == nil)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                HStack(alignment: .top, spacing: 14) {
                    if model.core.mode == .countdown {
                        VStack(alignment: .leading, spacing: 12) {
                            presets
                            segments
                        }.frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        GroupBox("提醒文字") {
                            VStack(alignment: .leading, spacing: 8) {
                                TextField("可输入课堂提示", text: $messageDraft)
                                HStack {
                                    Button("显示文字") { model.message = messageDraft.trimmingCharacters(in: .whitespacesAndNewlines) }
                                    Button("清除文字") { messageDraft = ""; model.message = "" }
                                }
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }
                        projection
                    }.frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
            .padding(22)
        }
        .background(FloatingLecturerWindow().frame(width: 0, height: 0))
        .frame(minWidth: 780, minHeight: 430)
        .onAppear(perform: model.launch)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
            model.refreshDisplays()
            if model.overlayVisible { model.moveOverlay() }
        }
        .onExitCommand { if model.fullscreen { model.setFullscreen(false) } }
    }

    private var segments: some View {
        GroupBox("分段计时") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(model.draftSegments.indices), id: \.self) { i in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(String(format: "%02d", i + 1)).monospacedDigit()
                            TextField("阶段名称（选填）", text: $model.draftSegments[i].name)
                            Button("删除") { model.removeSegment(i) }.disabled(model.draftSegments.count == 1)
                        }
                        HStack {
                            Stepper("\(model.draftSegments[i].hours) 小时", value: $model.draftSegments[i].hours, in: 0...999)
                            Stepper("\(model.draftSegments[i].minutes) 分", value: $model.draftSegments[i].minutes, in: 0...59)
                            Stepper("\(model.draftSegments[i].seconds) 秒", value: $model.draftSegments[i].seconds, in: 0...59)
                        }
                    }
                    if i < model.draftSegments.count - 1 { Divider() }
                }
                HStack {
                    Button("＋ 增加一段", action: model.addSegment)
                    Button("应用段落时间", action: model.applySegments).buttonStyle(.borderedProminent)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var presets: some View {
        GroupBox("计时方案") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Picker("已有计时方案", selection: $model.presetSelection) {
                        Text("选择已有方案").tag("")
                        ForEach(model.presets) { Text($0.name).tag($0.id) }
                    }.labelsHidden()
                    Button("加载", action: model.loadPreset).disabled(model.presetSelection.isEmpty)
                    Button("删除") { confirmDelete = true }.disabled(model.presetSelection.isEmpty)
                }
                HStack {
                    TextField("方案名称", text: $model.presetName)
                    Button("保存") { model.savePreset(asNew: false) }
                    Button("另存为") { model.savePreset(asNew: true) }
                }
                if !model.presetStatus.isEmpty {
                    Text(model.presetStatus).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .confirmationDialog("确定删除选中的计时方案吗？", isPresented: $confirmDelete) {
            Button("删除", role: .destructive, action: model.deleteSelectedPreset)
        }
    }

    private var projection: some View {
        GroupBox("投影和学员窗口") {
            VStack(alignment: .leading, spacing: 8) {
                Picker("显示器", selection: $model.displayID) {
                    ForEach(model.displays) { Text($0.name).tag($0.id) }
                }.disabled(model.displays.isEmpty)
                HStack {
                    Button("移到所选屏幕", action: model.moveOverlay)
                    Button(model.overlayVisible ? "隐藏学员端" : "显示学员端") { model.showOverlay(!model.overlayVisible) }
                }
                HStack {
                    ForEach(DisplaySize.allCases) { size in Button(size.rawValue) { model.chooseSize(size) } }
                    Button(model.fullscreen ? "退出全屏" : "全屏") { model.setFullscreen(!model.fullscreen) }
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct NextSegmentButtonStyle: ButtonStyle {
    var onPress: @MainActor (Bool) -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
            .opacity(configuration.isPressed ? 0.7 : 1)
            .onChange(of: configuration.isPressed) { _, pressed in onPress(pressed) }
    }
}

@main
struct ClassTimerApp: App {
    @StateObject private var model = TimerModel()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup("ClassTimer 2.6 · 讲师控制端", id: "lecturer") { LecturerView(model: model) }
            .defaultSize(width: 850, height: 760)
            .windowResizability(.contentMinSize)

        MenuBarExtra("ClassTimer", systemImage: "timer") {
            Button("显示讲师控制端") {
                openWindow(id: "lecturer")
                NSApp.activate()
            }
            Button(model.overlayVisible ? "隐藏学员计时窗口" : "显示学员计时窗口") {
                model.showOverlay(!model.overlayVisible)
            }
            Button("退出学员全屏") { model.setFullscreen(false) }.disabled(!model.fullscreen)
            Divider()
            Button("退出 ClassTimer") { NSApp.terminate(nil) }.keyboardShortcut("q")
        }
    }
}
