import Foundation

// MARK: - Cross-device sync policy (Story 7.4 / architecture §8.3)
//
// The Apple Watch companion and the iPhone each run their own drift-safe `TimerEngine`.
// Keeping the two faces consistent is the crux of Epic 7, and it is pure *policy*:
//   - which device owns the active session, so a control tap goes to the right place, and
//   - how to reconcile two snapshots that were produced independently (last-write-wins).
//
// That policy lives here, in the platform-agnostic Domain layer, so it can be unit-tested
// with `swift test` — no paired hardware, no `WCSession`. The transport (WatchConnectivity)
// is a thin adapter on each side that defers every decision to these functions.

/// Which device produced or owns a piece of timer state.
public enum DeviceRole: String, Codable, Sendable {
    case phone
    case watch
}

/// A discrete control command exchanged when a non-owner device drives the session.
public enum SyncCommand: String, Codable, Sendable {
    case start, pause, resume, skip, stop
}

/// The canonical, cross-device timer snapshot exchanged over WatchConnectivity.
///
/// This is the App-Group `SharedTimerState` (§6.2) extended with the three fields the sync
/// authority needs: the `owner` of the active session (for control routing), a monotonic
/// per-origin `revision`, and a wall-clock `updatedAt`. Those drive deterministic
/// last-write-wins reconciliation. The lightweight App-Group snapshot omits them because a
/// per-device app↔widget mirror is never merged against a competing copy — only the
/// cross-device channel is.
public struct TimerSnapshot: Codable, Equatable, Sendable {
    public var state: TimerState
    public var sessionType: SessionType
    public var remainingSeconds: Int
    /// Total length of the current session in seconds, so a mirroring device can draw the ring.
    public var totalSeconds: Int
    public var expectedEndDate: Date?
    public var completedWorkSessions: Int
    /// The device that started (and therefore owns) the active session, if any.
    public var owner: DeviceRole?
    /// Monotonic per-origin counter, bumped on every locally-produced change.
    public var revision: UInt64
    /// The device that produced *this* snapshot.
    public var origin: DeviceRole
    /// Wall-clock time this snapshot was produced (primary last-write-wins key).
    public var updatedAt: Date

    public init(
        state: TimerState,
        sessionType: SessionType,
        remainingSeconds: Int,
        expectedEndDate: Date?,
        completedWorkSessions: Int,
        owner: DeviceRole?,
        revision: UInt64,
        origin: DeviceRole,
        updatedAt: Date,
        totalSeconds: Int = 0
    ) {
        self.state = state
        self.sessionType = sessionType
        self.remainingSeconds = remainingSeconds
        self.totalSeconds = totalSeconds
        self.expectedEndDate = expectedEndDate
        self.completedWorkSessions = completedWorkSessions
        self.owner = owner
        self.revision = revision
        self.origin = origin
        self.updatedAt = updatedAt
    }

    /// `true` while a session is running or paused (i.e. there is something to own).
    public var isActive: Bool { state == .running || state == .paused }

    /// A fresh idle snapshot produced by `origin`.
    public static func idle(origin: DeviceRole, at date: Date) -> TimerSnapshot {
        TimerSnapshot(
            state: .idle, sessionType: .work, remainingSeconds: 0, expectedEndDate: nil,
            completedWorkSessions: 0, owner: nil, revision: 0, origin: origin, updatedAt: date
        )
    }
}

/// The outcome of reconciling the local snapshot against one arriving from the peer.
public enum SyncResolution: String, Equatable, Sendable {
    case takeLocal
    case takeRemote
}

/// Pure last-write-wins reconciliation for two competing snapshots (architecture §8.3).
public enum TimerReconciler {
    /// Deterministic winner between the `local` snapshot and one arriving from the peer.
    ///
    /// Key order: newer `updatedAt` wins; ties break to the higher `revision`; remaining ties
    /// prefer an active session over idle; a final tie resolves to the `.phone` origin. The last
    /// rule matters — because it is total and symmetric, both devices independently compute the
    /// *same* winner from the same pair, so they converge without a round-trip.
    public static func resolve(local: TimerSnapshot, remote: TimerSnapshot) -> SyncResolution {
        if local.updatedAt != remote.updatedAt {
            return local.updatedAt > remote.updatedAt ? .takeLocal : .takeRemote
        }
        if local.revision != remote.revision {
            return local.revision > remote.revision ? .takeLocal : .takeRemote
        }
        if local.isActive != remote.isActive {
            return local.isActive ? .takeLocal : .takeRemote
        }
        if local.origin != remote.origin {
            return local.origin == .phone ? .takeLocal : .takeRemote
        }
        return .takeLocal
    }

    /// Convenience: the winning snapshot itself.
    public static func merged(local: TimerSnapshot, remote: TimerSnapshot) -> TimerSnapshot {
        resolve(local: local, remote: remote) == .takeLocal ? local : remote
    }
}

/// Where a control command should be handled.
public enum CommandRouting: String, Equatable, Sendable {
    case applyLocally
    case forwardToPeer
}

/// Decides whether this device applies a command locally or forwards it to the peer that owns
/// the active session (architecture §8.3): "if the iPhone owns the active session, the tap is
/// forwarded to it; otherwise the watch acts locally."
public enum TimerAuthority {
    /// - Parameters:
    ///   - command: the control the user just invoked.
    ///   - snapshot: this device's current view of the shared session.
    ///   - thisDevice: the device asking (`.phone` or `.watch`).
    ///   - peerReachable: whether the counterpart is reachable *right now* (live `sendMessage`);
    ///     when it is not, we act locally rather than drop the tap, and the change reconciles
    ///     on the next `applicationContext` exchange.
    public static func route(
        command: SyncCommand,
        snapshot: TimerSnapshot,
        thisDevice: DeviceRole,
        peerReachable: Bool
    ) -> CommandRouting {
        // A clean slate: whoever taps Start (or anything) becomes the owner — always local.
        guard snapshot.isActive else { return .applyLocally }
        // There is an active session. If we own it, act locally.
        let owner = snapshot.owner ?? snapshot.origin
        if owner == thisDevice { return .applyLocally }
        // The peer owns it: forward when reachable, else fall back to local control.
        return peerReachable ? .forwardToPeer : .applyLocally
    }
}

/// Merges focus sessions synced from another device into the local set, de-duplicated by
/// `FocusSession.id` (Story 7.6). A session that ran on the watch and later syncs to the phone
/// must never be counted twice — the id is stable across devices, so it is the dedupe key.
public enum SessionMerger {
    /// Union of `existing` and `incoming`, keyed by id (existing wins on collision), sorted by
    /// start time ascending. Feeding the result to `StatisticsEngine` yields no double-counting.
    public static func merge(existing: [FocusSession], incoming: [FocusSession]) -> [FocusSession] {
        var byID: [UUID: FocusSession] = [:]
        for session in existing { byID[session.id] = session }
        for session in incoming where byID[session.id] == nil { byID[session.id] = session }
        return byID.values.sorted { $0.startTime < $1.startTime }
    }
}
