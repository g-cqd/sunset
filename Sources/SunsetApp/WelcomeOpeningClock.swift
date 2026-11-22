import Foundation
import Observation
import SunsetRuntime

/// When the opening began, for the window's content to follow it (its blur), until it ends or is cut short.
@MainActor @Observable final class WelcomeOpeningClock {
    private(set) var start: Date?

    func begin() {
        start = Runtime.live.now()
    }

    func finish() {
        start = nil
    }
}
