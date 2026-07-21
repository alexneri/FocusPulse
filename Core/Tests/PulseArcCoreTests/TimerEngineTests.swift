import XCTest
import Combine
@testable import PulseArcCore

@MainActor
final class TimerEngineTests: XCTestCase {
    /// Mutable clock the test controls; `TimerEngine` reads `now` from it.
    private final class Clock {
        var now: Date
        init(_ start: Date = Date(timeIntervalSince1970: 0)) { now = start }
    }

    private func makeEngine(
        _ config: TimerConfiguration = .default
    ) -> (engine: TimerEngine, clock: Clock) {
        let clock = Clock()
        let engine = TimerEngine(configuration: config, now: { clock.now })
        return (engine, clock)
    }

    /// Advance the clock past the current session's end and tick to force completion.
    private func completeSession(_ engine: TimerEngine, _ clock: Clock) {
        guard let end = engine.expectedEndDate else { return }
        clock.now = end.addingTimeInterval(1)
        engine.tick()
    }

    func test_initialStateIsIdleWork() {
        let (engine, _) = makeEngine()
        XCTAssertEqual(engine.state, .idle)
        XCTAssertEqual(engine.sessionType, .work)
        XCTAssertEqual(engine.remainingSeconds, 25 * 60)
    }

    func test_startEntersRunningWork() {
        let (engine, _) = makeEngine()
        engine.start()
        XCTAssertEqual(engine.state, .running)
        XCTAssertEqual(engine.sessionType, .work)
        XCTAssertNotNil(engine.expectedEndDate)
    }

    func test_tickDerivesRemainingFromClock() {
        let (engine, clock) = makeEngine()
        engine.start()
        clock.now = clock.now.addingTimeInterval(60) // 1 minute elapsed
        engine.tick()
        XCTAssertEqual(engine.remainingSeconds, 24 * 60)
    }

    func test_workCompletesToShortBreak() {
        let (engine, clock) = makeEngine()
        engine.start()
        completeSession(engine, clock)
        XCTAssertEqual(engine.sessionType, .shortBreak)
        XCTAssertEqual(engine.state, .running)
        XCTAssertEqual(engine.completedWorkSessions, 1)
    }

    func test_fourthWorkCompletesToLongBreak() {
        let (engine, clock) = makeEngine()
        engine.start()
        // work1 -> short -> work2 -> short -> work3 -> short -> work4 -> LONG
        for _ in 0..<6 { completeSession(engine, clock) } // through work3's short break back to work4
        XCTAssertEqual(engine.sessionType, .work)
        XCTAssertEqual(engine.completedWorkSessions, 3)
        completeSession(engine, clock) // complete work4
        XCTAssertEqual(engine.completedWorkSessions, 4)
        XCTAssertEqual(engine.sessionType, .longBreak)
    }

    func test_pauseFreezesRemainingAndResumeContinues() {
        let (engine, clock) = makeEngine()
        engine.start()
        clock.now = clock.now.addingTimeInterval(5 * 60) // 5 min elapsed -> 20 min left
        engine.tick()
        engine.pause()
        XCTAssertEqual(engine.state, .paused)
        XCTAssertEqual(engine.remainingSeconds, 20 * 60)
        // Time passes while paused; remaining must not change.
        clock.now = clock.now.addingTimeInterval(10 * 60)
        engine.tick() // no-op while paused
        XCTAssertEqual(engine.remainingSeconds, 20 * 60)
        engine.resume()
        XCTAssertEqual(engine.state, .running)
        XCTAssertEqual(engine.remainingSeconds, 20 * 60)
    }

    func test_idleCannotPause() {
        let (engine, _) = makeEngine()
        engine.pause()
        XCTAssertEqual(engine.state, .idle)
    }

    func test_skipAdvancesToNextSession() {
        let (engine, _) = makeEngine()
        engine.start()
        engine.skip()
        XCTAssertEqual(engine.sessionType, .shortBreak)
        XCTAssertEqual(engine.completedWorkSessions, 1)
    }

    func test_stopResetsEverything() {
        let (engine, clock) = makeEngine()
        engine.start()
        completeSession(engine, clock)
        engine.stop()
        XCTAssertEqual(engine.state, .idle)
        XCTAssertEqual(engine.sessionType, .work)
        XCTAssertEqual(engine.completedWorkSessions, 0)
        XCTAssertEqual(engine.remainingSeconds, 25 * 60)
        XCTAssertNil(engine.expectedEndDate)
    }

    func test_onSessionCompletedFiresWithBounds() {
        let (engine, clock) = makeEngine()
        var completed: [(SessionType, Date, Date)] = []
        engine.onSessionCompleted = { type, start, end in completed.append((type, start, end)) }
        engine.start()
        completeSession(engine, clock)
        XCTAssertEqual(completed.count, 1)
        XCTAssertEqual(completed.first?.0, .work)
        if let (_, start, end) = completed.first {
            XCTAssertGreaterThan(end, start)
        }
    }
}
