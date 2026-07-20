import XCTest
@testable import PulseArcCore

final class StatisticsEngineTests: XCTestCase {
    private static let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()
    private let engine = StatisticsEngine(calendar: StatisticsEngineTests.cal)

    private func session(
        _ type: SessionType,
        start: Date,
        minutes: Int,
        status: FocusSession.Status = .completed
    ) -> FocusSession {
        FocusSession(
            type: type,
            startTime: start,
            endTime: start.addingTimeInterval(TimeInterval(minutes * 60)),
            status: status
        )!
    }

    private func day(_ offsetDays: Int, hour: Int = 9) -> Date {
        var c = DateComponents()
        c.year = 2024; c.month = 1; c.day = 1 + offsetDays; c.hour = hour
        return Self.cal.date(from: c)!
    }

    func test_totalFocusTimeCountsOnlyCompletedWork() {
        let sessions = [
            session(.work, start: day(0), minutes: 25),
            session(.work, start: day(0, hour: 11), minutes: 25),
            session(.shortBreak, start: day(0, hour: 12), minutes: 5),      // ignored
            session(.work, start: day(0, hour: 13), minutes: 25, status: .abandoned) // ignored
        ]
        XCTAssertEqual(engine.totalFocusTime(sessions), TimeInterval(50 * 60))
    }

    func test_dailyStatsGroupByDay() {
        let sessions = [
            session(.work, start: day(0), minutes: 25),
            session(.work, start: day(0, hour: 14), minutes: 25),
            session(.work, start: day(1), minutes: 25)
        ]
        let stats = engine.dailyStats(sessions)
        XCTAssertEqual(stats.count, 2)
        XCTAssertEqual(stats[0].sessionsCompleted, 2)
        XCTAssertEqual(stats[1].sessionsCompleted, 1)
        XCTAssertLessThan(stats[0].date, stats[1].date)
    }

    func test_currentStreakCountsConsecutiveDays() {
        let sessions = [
            session(.work, start: day(0), minutes: 25),
            session(.work, start: day(1), minutes: 25),
            session(.work, start: day(2), minutes: 25)
        ]
        // reference = same day as day(2)
        XCTAssertEqual(engine.currentStreak(sessions, asOf: day(2, hour: 20)), 3)
    }

    func test_streakBreaksOnGap() {
        let sessions = [
            session(.work, start: day(0), minutes: 25),
            session(.work, start: day(2), minutes: 25) // gap on day 1
        ]
        XCTAssertEqual(engine.currentStreak(sessions, asOf: day(2, hour: 20)), 1)
    }

    func test_bestFocusHour() {
        let sessions = [
            session(.work, start: day(0, hour: 9), minutes: 25),
            session(.work, start: day(1, hour: 9), minutes: 25),  // 9am total 50 min
            session(.work, start: day(0, hour: 14), minutes: 25)  // 2pm total 25 min
        ]
        XCTAssertEqual(engine.bestFocusHour(sessions), 9)
    }

    func test_emptyInputs() {
        XCTAssertEqual(engine.totalFocusTime([]), 0)
        XCTAssertTrue(engine.dailyStats([]).isEmpty)
        XCTAssertEqual(engine.currentStreak([], asOf: day(0)), 0)
        XCTAssertNil(engine.bestFocusHour([]))
    }
}
