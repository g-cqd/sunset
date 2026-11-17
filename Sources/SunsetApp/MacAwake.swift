import Foundation
import Observation
import SunsetConfig
import SunsetShell

/// Holds the system's "do not sleep" while a tab or a window wants the Mac awake (roadmap 0035 E): one activity for the app,
/// begun when the first wants it, ended when the last lets go; with `tabs.keepAwakeDisplay`, the display stays on too.
/// Follows the windows' models by observation: a command that ends, a tab closed, a setting changed, a window gone.
@MainActor
final class MacAwake {
    static let shared = MacAwake()

    private var activity: (any NSObjectProtocol)?
    private var display = false

    /// Looks again at what the windows want, and keeps looking until it changes.
    func update() {
        let windows = TabRegistry.shared.allWindows().map(\.tabs)
        // What no longer applies is forgotten first (a command ended), outside the observation.
        for tabs in windows { tabs.settleAwake() }
        let (wanted, keepsDisplay) = withObservationTracking {
            (windows.contains { $0.keepsMacAwake }, AppConfiguration.shared.configuration.tabs.keepAwakeDisplay)
        } onChange: {
            Task { @MainActor in MacAwake.shared.update() }
        }
        hold(wanted, display: keepsDisplay)
    }

    private func hold(_ wanted: Bool, display keepsDisplay: Bool) {
        if let activity, !wanted || keepsDisplay != display {
            ProcessInfo.processInfo.endActivity(activity)
            self.activity = nil
        }
        guard wanted, activity == nil else { return }
        var options: ProcessInfo.ActivityOptions = [.idleSystemSleepDisabled, .userInitiated]
        if keepsDisplay { options.insert(.idleDisplaySleepDisabled) }
        activity = ProcessInfo.processInfo.beginActivity(options: options, reason: "A tab or a window is kept awake")
        display = keepsDisplay
    }
}
