import XCTest
@testable import PulseArcCore

final class SessionCyclerTests: XCTestCase {
    private let cycler = SessionCycler(longBreakInterval: 4)

    func test_workBeforeIntervalGoesToShortBreak() {
        XCTAssertEqual(cycler.next(after: .work, completedWorkSessions: 1), .shortBreak)
        XCTAssertEqual(cycler.next(after: .work, completedWorkSessions: 2), .shortBreak)
        XCTAssertEqual(cycler.next(after: .work, completedWorkSessions: 3), .shortBreak)
    }

    func test_everyFourthWorkGoesToLongBreak() {
        XCTAssertEqual(cycler.next(after: .work, completedWorkSessions: 4), .longBreak)
        XCTAssertEqual(cycler.next(after: .work, completedWorkSessions: 8), .longBreak)
    }

    func test_anyBreakGoesToWork() {
        XCTAssertEqual(cycler.next(after: .shortBreak, completedWorkSessions: 2), .work)
        XCTAssertEqual(cycler.next(after: .longBreak, completedWorkSessions: 4), .work)
    }

    func test_intervalIsClampedToMinimumTwo() {
        XCTAssertEqual(SessionCycler(longBreakInterval: 0).longBreakInterval, 2)
    }
}
