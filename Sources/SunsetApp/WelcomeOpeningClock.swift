import Foundation
import Observation
import QuartzCore
import SunsetRuntime

/// The single shared clock for the welcome's opening: the sun panel (`SunsetSkyLayerView`), the window's opacity ramp
/// (`WelcomeOpeningPlayer`), the window content's blur (`WelcomeOpeningFocus`), and the score (`WelcomeOpeningAudio`)
/// all advance from the same start moment so audio and visuals stay locked in sync.
@MainActor @Observable final class WelcomeOpeningClock {
    /// Wall-clock start (for SwiftUI's `TimelineView`), offset by audio output latency so visuals begin when sound hits the air.
    private(set) var start: Date?
    /// Monotonic media-time start (`CACurrentMediaTime()`), paired with `start`.
    private(set) var mediaStart: Double?

    /// Anchors the opening `delay` seconds from now (e.g. `AVAudioOutputNode.presentationLatency`).
    func begin(delay: TimeInterval = 0) {
        let offset = max(0, delay)
        start = Runtime.live.now().addingTimeInterval(offset)
        mediaStart = CACurrentMediaTime() + offset
    }

    /// Seconds elapsed since the opening began, clamped to `>= 0`.
    func elapsed(at mediaTime: Double = CACurrentMediaTime()) -> Double {
        guard let mediaStart else { return 0 }
        return max(0, mediaTime - mediaStart)
    }

    func finish() {
        start = nil
        mediaStart = nil
    }
}
