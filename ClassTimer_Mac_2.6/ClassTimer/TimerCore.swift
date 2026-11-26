import Foundation

enum TimerMode: String, CaseIterable, Identifiable {
    case countdown = "倒计时", stopwatch = "秒表", clock = "时钟", alarm = "闹钟"

    var id: Self { self }
}

struct TimerSegment: Codable, Equatable {
    var name = ""
    var hours = 0
    var minutes = 15
    var seconds = 0

    var duration: Int {
        max(1, min(999, max(0, hours)) * 3600 + min(59, max(0, minutes)) * 60 + min(59, max(0, seconds)))
    }

    mutating func setDuration(_ duration: Int) {
        let value = min(3_599_999, max(1, duration))
        hours = value / 3600
        minutes = value % 3600 / 60
        seconds = value % 60
    }
}

struct TimerPreset: Codable, Identifiable, Equatable {
    var id = UUID().uuidString
    var name: String
    var segments: [TimerSegment]
}

struct TimerCore: Equatable {
    enum State: Equatable { case ready, running, paused, finished }

    private(set) var mode = TimerMode.countdown
    private(set) var state = State.ready
    private(set) var segments = [TimerSegment()]
    private(set) var index = 0
    private(set) var displayedSeconds = 900
    var loop = false
    private(set) var alarmDate: Date?
    private(set) var countdownAlert = false
    private(set) var alarmAlert = false
    private var startUptime: TimeInterval = 0
    private var startingSeconds = 900

    var current: TimerSegment { segments[index] }
    var alertActive: Bool { countdownAlert || alarmAlert }
    var canAdvance: Bool {
        mode == .countdown && (state == .running || state == .paused) && index + 1 < segments.count
    }

    mutating func changeMode(_ mode: TimerMode) {
        guard self.mode != mode else { return }
        self.mode = mode
        reset()
    }

    mutating func applySegments(_ newSegments: [TimerSegment]) {
        guard !newSegments.isEmpty else { return }
        segments = newSegments
        reset()
    }

    mutating func start(at uptime: TimeInterval) {
        guard mode == .countdown || mode == .stopwatch, state != .running else { return }
        if state == .finished { reset() }
        if mode == .countdown && displayedSeconds == 0 { displayedSeconds = current.duration }
        beginRunning(at: uptime)
    }

    mutating func pause(at uptime: TimeInterval, now: Date) {
        guard state == .running else { return }
        tick(at: uptime, now: now)
        guard state == .running else { return }
        state = .paused
    }

    mutating func reset() {
        index = 0
        state = .ready
        countdownAlert = false
        displayedSeconds = mode == .countdown ? current.duration : 0
    }

    mutating func adjustMinute(_ delta: Int, at uptime: TimeInterval, now: Date) {
        guard mode == .countdown else { return }
        tick(at: uptime, now: now)
        let shift = delta * 60
        segments[index].setDuration(current.duration + shift)
        displayedSeconds = min(3_599_999, max(0, displayedSeconds + shift))
        if state == .running { beginRunning(at: uptime) }
    }

    mutating func advance(at uptime: TimeInterval, expectedIndex: Int) {
        guard index == expectedIndex, canAdvance else { return }
        startSegment(index + 1, at: uptime)
    }

    mutating func armAlarm(_ target: Date) {
        alarmDate = target
        alarmAlert = false
    }

    mutating func cancelAlarm() {
        alarmDate = nil
        alarmAlert = false
    }

    mutating func stopAlert() {
        alarmAlert = false
        countdownAlert = false
    }

    mutating func tick(at uptime: TimeInterval, now: Date) {
        if let alarmDate, alarmDate <= now {
            self.alarmDate = nil
            alarmAlert = true
        }
        guard state == .running else { return }
        let elapsed = max(0, Int(uptime - startUptime))
        if mode == .stopwatch {
            displayedSeconds = startingSeconds + elapsed
            return
        }
        guard mode == .countdown else { return }
        displayedSeconds = max(0, startingSeconds - elapsed)
        guard displayedSeconds == 0 else { return }
        if index + 1 < segments.count || loop {
            startSegment(index + 1 < segments.count ? index + 1 : 0, at: uptime)
        } else {
            state = .finished
            countdownAlert = true
        }
    }

    func formattedTime(now: Date) -> String {
        if mode == .clock || mode == .alarm {
            return now.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).second(.twoDigits).locale(Locale(identifier: "en_GB")))
        }
        if displayedSeconds >= 3600 {
            return String(format: "%02d:%02d:%02d", displayedSeconds / 3600, displayedSeconds % 3600 / 60, displayedSeconds % 60)
        }
        return String(format: "%02d:%02d", displayedSeconds / 60, displayedSeconds % 60)
    }

    private mutating func beginRunning(at uptime: TimeInterval) {
        startUptime = uptime
        startingSeconds = displayedSeconds
        state = .running
    }

    private mutating func startSegment(_ segment: Int, at uptime: TimeInterval) {
        index = segment
        displayedSeconds = current.duration
        beginRunning(at: uptime)
    }
}
