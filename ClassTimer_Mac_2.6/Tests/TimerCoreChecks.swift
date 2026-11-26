import Foundation

@main
struct TimerCoreChecks {
    static func main() throws {
        let date = Date(timeIntervalSince1970: 1_000)
        let segments = [
            TimerSegment(name: "讨论", minutes: 0, seconds: 1),
            TimerSegment(name: "汇报", minutes: 0, seconds: 45),
            TimerSegment(name: "复盘", minutes: 1)
        ]
        var core = TimerCore()
        core.applySegments(segments)
        core.advance(at: 0, expectedIndex: 0)
        precondition(core.index == 0 && core.state == .ready)
        core.start(at: 1)
        core.advance(at: 2, expectedIndex: 0)
        core.tick(at: 2, now: date)
        precondition(core.index == 1 && core.displayedSeconds == 45 && core.state == .running)
        core.pause(at: 4, now: date)
        core.tick(at: 17, now: date)
        precondition(core.state == .paused && core.displayedSeconds == 43)
        core.advance(at: 17, expectedIndex: 1)
        precondition(core.index == 2 && core.displayedSeconds == 60 && core.state == .running)
        core.loop = true
        core.advance(at: 17, expectedIndex: 2)
        precondition(core.index == 2 && !core.canAdvance)
        core.tick(at: 77, now: date)
        precondition(core.index == 0 && core.displayedSeconds == 1)
        core.tick(at: 78, now: date)
        core.advance(at: 78, expectedIndex: 0)
        precondition(core.index == 1 && core.displayedSeconds == 45)
        core.adjustMinute(1, at: 79, now: date)
        precondition(core.displayedSeconds == 104)
        core.changeMode(.stopwatch)
        core.start(at: 100)
        core.tick(at: 102, now: date)
        precondition(core.displayedSeconds == 2 && !core.canAdvance)
        core.armAlarm(date.addingTimeInterval(1))
        core.tick(at: 103, now: date.addingTimeInterval(1))
        precondition(core.alarmAlert && core.alarmDate == nil)
        core.stopAlert()
        precondition(!core.alertActive)
        let legacy = Data(#"[{"id":"test","name":"课程","segments":[{"name":"讨论","hours":0,"minutes":5,"seconds":5}]}]"#.utf8)
        let restored = try JSONDecoder().decode([TimerPreset].self, from: legacy)
        precondition(restored.first?.segments.first?.duration == 305)
        print("PASS: manual advance, pause, coincident expiry, automatic loop, adjustment, stopwatch, alarm, and preset decoding")
    }
}
