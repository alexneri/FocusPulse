import XCTest
@testable import FocusPulseCore

/// Unit tests for the cross-device sync policy (Story 7.4 / 7.6). These are the crux of the
/// Apple Watch companion, and because the policy is pure they are fully verifiable here with no
/// paired hardware or `WCSession`.
final class WatchSyncTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_000_000)

    private func snap(
        _ state: TimerState,
        origin: DeviceRole,
        owner: DeviceRole? = nil,
        rev: UInt64 = 1,
        at offset: TimeInterval = 0
    ) -> TimerSnapshot {
        TimerSnapshot(
            state: state, sessionType: .work, remainingSeconds: 1500, expectedEndDate: nil,
            completedWorkSessions: 0, owner: owner, revision: rev, origin: origin,
            updatedAt: t0.addingTimeInterval(offset)
        )
    }

    // MARK: - Reconciliation (last-write-wins)

    func testNewerTimestampWins() {
        let local = snap(.running, origin: .phone, at: 10)
        let remote = snap(.paused, origin: .watch, at: 20)
        XCTAssertEqual(TimerReconciler.resolve(local: local, remote: remote), .takeRemote)
    }

    func testRevisionBreaksTimestampTie() {
        let local = snap(.running, origin: .phone, rev: 5, at: 10)
        let remote = snap(.paused, origin: .watch, rev: 9, at: 10)
        XCTAssertEqual(TimerReconciler.resolve(local: local, remote: remote), .takeRemote)
    }

    func testActiveBeatsIdleOnFullTie() {
        let local = snap(.running, origin: .phone, rev: 3, at: 10)   // active
        let remote = snap(.idle, origin: .watch, rev: 3, at: 10)     // idle
        XCTAssertEqual(TimerReconciler.resolve(local: local, remote: remote), .takeLocal)
    }

    func testDeterministicPhoneTieBreakIsSymmetric() {
        // Same time, same revision, both active, differing origins: phone must win regardless of
        // which side is "local", so both devices converge on the same snapshot.
        let phone = snap(.running, origin: .phone, rev: 3, at: 10)
        let watch = snap(.running, origin: .watch, rev: 3, at: 10)
        XCTAssertEqual(TimerReconciler.resolve(local: phone, remote: watch), .takeLocal)
        XCTAssertEqual(TimerReconciler.resolve(local: watch, remote: phone), .takeRemote)
    }

    func testLaterStopOverridesActiveSession() {
        // The peer hit Stop after our session started: its idle snapshot is newer and must win,
        // even though ours is active and has a higher revision.
        let local = snap(.running, origin: .phone, rev: 4, at: 10)
        let remote = snap(.idle, origin: .watch, rev: 1, at: 25)
        XCTAssertEqual(TimerReconciler.resolve(local: local, remote: remote), .takeRemote)
        XCTAssertEqual(TimerReconciler.merged(local: local, remote: remote), remote)
    }

    // MARK: - Authority / command routing

    func testStartFromIdleAppliesLocally() {
        let idle = snap(.idle, origin: .phone)
        XCTAssertEqual(
            TimerAuthority.route(command: .start, snapshot: idle, thisDevice: .watch, peerReachable: true),
            .applyLocally
        )
    }

    func testOwnerActsLocally() {
        let phoneOwned = snap(.running, origin: .phone, owner: .phone, at: 10)
        XCTAssertEqual(
            TimerAuthority.route(command: .pause, snapshot: phoneOwned, thisDevice: .phone, peerReachable: true),
            .applyLocally
        )
    }

    func testNonOwnerForwardsWhenReachable() {
        let phoneOwned = snap(.running, origin: .phone, owner: .phone, at: 10)
        XCTAssertEqual(
            TimerAuthority.route(command: .pause, snapshot: phoneOwned, thisDevice: .watch, peerReachable: true),
            .forwardToPeer
        )
    }

    func testNonOwnerFallsBackToLocalWhenUnreachable() {
        let phoneOwned = snap(.running, origin: .phone, owner: .phone, at: 10)
        XCTAssertEqual(
            TimerAuthority.route(command: .pause, snapshot: phoneOwned, thisDevice: .watch, peerReachable: false),
            .applyLocally
        )
    }

    func testOwnerDefaultsToOriginWhenUnset() {
        // owner == nil -> fall back to the snapshot's origin as the owner.
        let watchRun = snap(.running, origin: .watch, owner: nil, at: 10)
        XCTAssertEqual(
            TimerAuthority.route(command: .skip, snapshot: watchRun, thisDevice: .watch, peerReachable: true),
            .applyLocally
        )
        XCTAssertEqual(
            TimerAuthority.route(command: .skip, snapshot: watchRun, thisDevice: .phone, peerReachable: true),
            .forwardToPeer
        )
    }

    // MARK: - Session sync-back de-duplication (Story 7.6)

    func testMergeDedupesByID() {
        let sharedID = UUID()
        let a = FocusSession(id: sharedID, type: .work, startTime: t0, endTime: t0.addingTimeInterval(1500))!
        let duplicate = FocusSession(id: sharedID, type: .work, startTime: t0, endTime: t0.addingTimeInterval(1500))!
        let b = FocusSession(type: .shortBreak, startTime: t0.addingTimeInterval(2000), endTime: t0.addingTimeInterval(2300))!

        let merged = SessionMerger.merge(existing: [a], incoming: [duplicate, b])
        XCTAssertEqual(merged.count, 2)
        XCTAssertEqual(Set(merged.map(\.id)), Set([sharedID, b.id]))
    }

    func testMergedSessionsDoNotDoubleCountInStatistics() {
        let id = UUID()
        let session = FocusSession(id: id, type: .work, startTime: t0, endTime: t0.addingTimeInterval(1500))!
        // The same work session, synced back from the watch, must count once — not twice.
        let merged = SessionMerger.merge(existing: [session], incoming: [session])
        XCTAssertEqual(StatisticsEngine().totalFocusTime(merged), 1500)
    }

    func testMergePreservesStartTimeOrder() {
        let late = FocusSession(type: .work, startTime: t0.addingTimeInterval(5000), endTime: t0.addingTimeInterval(6500))!
        let early = FocusSession(type: .work, startTime: t0, endTime: t0.addingTimeInterval(1500))!
        let merged = SessionMerger.merge(existing: [late], incoming: [early])
        XCTAssertEqual(merged.map(\.startTime), [early.startTime, late.startTime])
    }
}
