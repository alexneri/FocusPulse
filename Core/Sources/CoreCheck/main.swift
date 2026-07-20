import Foundation
import PulseArcCore

// A tiny, dependency-free verification runner for the Domain logic. Mirrors the XCTest suite
// so the core can be proven on a Command-Line-Tools-only machine (no Xcode / XCTest):
//   swift run CoreCheck
// Exits non-zero if any check fails. Top-level code runs on the main actor, so @MainActor
// TimerEngine calls are legal here.

var failures = 0
@MainActor func check(_ condition: Bool, _ message: String) {
    if condition {
        print("  ✓ \(message)")
    } else {
        print("  ✗ FAIL: \(message)")
        failures += 1
    }
}
@MainActor func eq<T: Equatable>(_ a: T, _ b: T, _ message: String) {
    check(a == b, "\(message) — got \(a), expected \(b)")
}

// MARK: SessionCycler
print("SessionCycler")
let cycler = SessionCycler(longBreakInterval: 4)
eq(cycler.next(after: .work, completedWorkSessions: 1), .shortBreak, "1st work → short break")
eq(cycler.next(after: .work, completedWorkSessions: 3), .shortBreak, "3rd work → short break")
eq(cycler.next(after: .work, completedWorkSessions: 4), .longBreak, "4th work → long break")
eq(cycler.next(after: .shortBreak, completedWorkSessions: 2), .work, "short break → work")
eq(cycler.next(after: .longBreak, completedWorkSessions: 4), .work, "long break → work")
eq(SessionCycler(longBreakInterval: 0).longBreakInterval, 2, "interval clamps to 2")

// MARK: TimerConfiguration
print("TimerConfiguration")
eq(TimerConfiguration.default.workDuration, 1500, "default work = 1500s")
eq(TimerConfiguration(workMinutes: 999).workDuration, 7200, "work clamps to 120 min")
eq(TimerConfiguration(longBreakInterval: 99).longBreakInterval, 8, "interval clamps to 8")

// MARK: FocusSession invariant
print("FocusSession")
let base = Date(timeIntervalSince1970: 1_700_000_000)
check(FocusSession(type: .work, startTime: base, endTime: base.addingTimeInterval(1500)) != nil,
      "valid session constructs")
check(FocusSession(type: .work, startTime: base, endTime: base) == nil,
      "zero-length session rejected (endTime must be > startTime)")

// MARK: TimerEngine
print("TimerEngine")
final class Clock { var now = Date(timeIntervalSince1970: 0) }
let clock = Clock()
let engine = TimerEngine(configuration: .default, now: { clock.now })

@MainActor func completeCurrentSession() {
    if let end = engine.expectedEndDate {
        clock.now = end.addingTimeInterval(1)
        engine.tick()
    }
}

eq(engine.state, .idle, "starts idle")
eq(engine.remainingSeconds, 1500, "starts at 25:00")

engine.pause()
eq(engine.state, .idle, "idle can't pause (invalid transition blocked)")

engine.start()
eq(engine.state, .running, "start → running")
eq(engine.sessionType, .work, "starts a work session")

clock.now = clock.now.addingTimeInterval(60)
engine.tick()
eq(engine.remainingSeconds, 1440, "after 1 min → 24:00 (derived from clock, no drift)")

var completedCallbacks = 0
engine.onSessionCompleted = { _, start, end in
    completedCallbacks += 1
    check(end > start, "completed session has end > start")
}

completeCurrentSession()
eq(engine.sessionType, .shortBreak, "work complete → short break")
eq(engine.state, .running, "auto-cycles into the next session running")
eq(engine.completedWorkSessions, 1, "one work session recorded")
eq(completedCallbacks, 1, "completion callback fired once")

// Pause freezes remaining even as the clock advances.
completeCurrentSession() // short break → work2
engine.start() // no-op (already running)
clock.now = clock.now.addingTimeInterval(300)
engine.tick()
engine.pause()
let frozen = engine.remainingSeconds
clock.now = clock.now.addingTimeInterval(600)
engine.tick()
eq(engine.remainingSeconds, frozen, "remaining frozen while paused")
engine.resume()
eq(engine.state, .running, "resume → running")

// Drive to the 4th completed work session → long break.
let c2 = Clock()
let e2 = TimerEngine(configuration: .default, now: { c2.now })
e2.start()
@MainActor func advance(_ engine: TimerEngine, _ clock: Clock) {
    if let end = engine.expectedEndDate { clock.now = end.addingTimeInterval(1); engine.tick() }
}
// work1, short, work2, short, work3, short → back at work4
for _ in 0..<6 { advance(e2, c2) }
eq(e2.completedWorkSessions, 3, "3 work sessions done before 4th")
eq(e2.sessionType, .work, "sitting on the 4th work session")
advance(e2, c2)
eq(e2.completedWorkSessions, 4, "4 work sessions done")
eq(e2.sessionType, .longBreak, "4th work → LONG break")

// Stop resets the whole cycle.
e2.stop()
eq(e2.state, .idle, "stop → idle")
eq(e2.completedWorkSessions, 0, "stop resets cycle count")
eq(e2.sessionType, .work, "stop resets to work")

// Skip advances immediately.
let c3 = Clock()
let e3 = TimerEngine(now: { c3.now })
e3.start()
e3.skip()
eq(e3.sessionType, .shortBreak, "skip work → short break")

// MARK: StatisticsEngine
print("StatisticsEngine")
var statCal = Calendar(identifier: .gregorian)
statCal.timeZone = TimeZone(identifier: "UTC")!
let stats = StatisticsEngine(calendar: statCal)

@MainActor func day(_ offset: Int, hour: Int = 9) -> Date {
    var c = DateComponents()
    c.year = 2024; c.month = 1; c.day = 1 + offset; c.hour = hour
    return statCal.date(from: c)!
}
@MainActor func mk(_ type: SessionType, _ start: Date, _ minutes: Int,
                   _ status: FocusSession.Status = .completed) -> FocusSession {
    FocusSession(type: type, startTime: start,
                 endTime: start.addingTimeInterval(TimeInterval(minutes * 60)), status: status)!
}
let sample = [
    mk(.work, day(0, hour: 9), 25),
    mk(.work, day(0, hour: 11), 25),
    mk(.shortBreak, day(0, hour: 12), 5),          // break — ignored
    mk(.work, day(0, hour: 13), 25, .abandoned),   // abandoned — ignored
    mk(.work, day(1, hour: 9), 25),
    mk(.work, day(2, hour: 14), 25)
]
eq(stats.totalFocusTime(sample), TimeInterval(100 * 60), "total = 4 completed work × 25 min")
eq(stats.dailyStats(sample).count, 3, "3 distinct days with work")
eq(stats.dailyStats(sample).first?.sessionsCompleted, 2, "day 0 has 2 completed work sessions")
eq(stats.currentStreak(sample, asOf: day(2, hour: 20)), 3, "3-day streak")
eq(stats.bestFocusHour(sample), 9, "best focus hour = 9am (50 min beats other hours)")
eq(stats.currentStreak([], asOf: day(0)), 0, "empty streak = 0")
check(stats.bestFocusHour([]) == nil, "no best hour for no sessions")

// MARK: WatchSync (cross-device policy — Story 7.4 / 7.6)
print("WatchSync")
let wt0 = Date(timeIntervalSince1970: 1_000_000)
@MainActor func wsnap(_ state: TimerState, origin: DeviceRole, owner: DeviceRole? = nil,
                      rev: UInt64 = 1, at offset: TimeInterval = 0) -> TimerSnapshot {
    TimerSnapshot(state: state, sessionType: .work, remainingSeconds: 1500, expectedEndDate: nil,
                  completedWorkSessions: 0, owner: owner, revision: rev, origin: origin,
                  updatedAt: wt0.addingTimeInterval(offset))
}
eq(TimerReconciler.resolve(local: wsnap(.running, origin: .phone, at: 10),
                           remote: wsnap(.paused, origin: .watch, at: 20)), .takeRemote,
   "newer snapshot wins")
eq(TimerReconciler.resolve(local: wsnap(.running, origin: .phone, rev: 3, at: 10),
                           remote: wsnap(.running, origin: .watch, rev: 3, at: 10)), .takeLocal,
   "phone wins a full tie (deterministic, symmetric)")
eq(TimerReconciler.resolve(local: wsnap(.running, origin: .phone, rev: 4, at: 10),
                           remote: wsnap(.idle, origin: .watch, rev: 1, at: 25)), .takeRemote,
   "a later Stop overrides an active session")
eq(TimerAuthority.route(command: .pause, snapshot: wsnap(.running, origin: .phone, owner: .phone, at: 10),
                        thisDevice: .watch, peerReachable: true), .forwardToPeer,
   "non-owner forwards to the owning device when reachable")
eq(TimerAuthority.route(command: .pause, snapshot: wsnap(.running, origin: .phone, owner: .phone, at: 10),
                        thisDevice: .watch, peerReachable: false), .applyLocally,
   "non-owner falls back to local control when the peer is unreachable")
eq(TimerAuthority.route(command: .start, snapshot: wsnap(.idle, origin: .phone),
                        thisDevice: .watch, peerReachable: true), .applyLocally,
   "start from idle is always local")
let wsA = FocusSession(type: .work, startTime: wt0, endTime: wt0.addingTimeInterval(1500))!
eq(SessionMerger.merge(existing: [wsA], incoming: [wsA]).count, 1,
   "sessions synced back de-duplicate by id")

// MARK: Result
print("")
if failures == 0 {
    print("ALL CHECKS PASSED ✅")
} else {
    print("\(failures) CHECK(S) FAILED ❌")
    exit(1)
}
