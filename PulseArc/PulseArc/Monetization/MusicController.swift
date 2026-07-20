import Foundation
import MusicKit
import PulseArcCore

/// Apple Music automation (Story 6.4). Mirrors the timer's run state onto the shared music player:
/// play on Work start/resume, pause on manual pause / break / stop. Pro-gated in the UI; degrades
/// gracefully without authorization or an Apple Music subscription (the timer is never affected).
///
/// The playlist/station picker and the MusicKit capability are configured separately; without a
/// selected queue `play()` is a no-op, so this is safe to wire in ahead of that.
@MainActor
final class MusicController {
    private let player = ApplicationMusicPlayer.shared
    private(set) var isAuthorized = false

    /// Requested lazily when the user enables automation (never at launch).
    func requestAuthorizationIfNeeded() async {
        guard !isAuthorized else { return }
        isAuthorized = (await MusicAuthorization.request()) == .authorized
    }

    /// React to a timer transition.
    /// - Parameter autoPauseOnBreak: pause the music during breaks (else keep playing through).
    func update(state: PulseArcCore.TimerState,
                sessionType: PulseArcCore.SessionType,
                autoPauseOnBreak: Bool) {
        guard isAuthorized else { return }
        switch state {
        case .running:
            if sessionType == .work || !autoPauseOnBreak {
                Task { try? await player.play() }
            } else {
                player.pause()
            }
        case .paused, .completed, .idle:
            player.pause()
        }
    }
}
