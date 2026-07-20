import Foundation
import WatchKit
import UserNotifications
import FocusPulseCore

// NOTE: FocusPulse Apple Watch source — NOT compiled into the iOS app target. See README.md.

/// Background continuation for the Apple Watch timer (Story 7.3).
///
/// watchOS has no clean background-countdown primitive, so — exactly as on the iPhone — the
/// **authoritative** end-of-session path is a date-based local notification scheduled at
/// `expectedEndDate` (drift-free; survives the app being suspended). A `WKExtendedRuntimeSession`
/// is an *optional enhancement* that keeps the face live a little longer after wrist-down; its
/// session types map imperfectly to a Pomodoro, so validate against App Review before relying on
/// it (flagged in Story 7.3 / the epic-7 gate).
final class WatchRuntime: NSObject {
    static let shared = WatchRuntime()

    private var runtimeSession: WKExtendedRuntimeSession?
    private static let sessionEndID = "focuspulse.session.end"

    func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// Schedule (or reschedule) the end-of-session alert. Call whenever a session (re)starts.
    func scheduleSessionEnd(at endDate: Date, sessionType: SessionType) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.sessionEndID])

        let content = UNMutableNotificationContent()
        content.title = sessionType == .work ? "Focus complete" : "Break complete"
        content.body = sessionType == .work ? "Time for a break." : "Back to focus."
        content.interruptionLevel = .timeSensitive

        let interval = max(1, endDate.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        center.add(UNNotificationRequest(identifier: Self.sessionEndID, content: content, trigger: trigger))
    }

    func cancelSessionEnd() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.sessionEndID])
    }

    /// Begin a foreground-adjacent runtime session so the face keeps updating briefly after wrist-down.
    func beginRuntimeSession() {
        let session = WKExtendedRuntimeSession()
        session.delegate = self
        session.start()
        runtimeSession = session
    }

    func endRuntimeSession() {
        runtimeSession?.invalidate()
        runtimeSession = nil
    }
}

extension WatchRuntime: WKExtendedRuntimeSessionDelegate {
    func extendedRuntimeSessionDidStart(_ session: WKExtendedRuntimeSession) {}
    func extendedRuntimeSessionWillExpire(_ session: WKExtendedRuntimeSession) {}
    func extendedRuntimeSession(
        _ session: WKExtendedRuntimeSession,
        didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
        error: Error?
    ) {
        runtimeSession = nil
    }
}
