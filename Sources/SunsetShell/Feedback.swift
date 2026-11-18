import AppKit

/// Says back what a click did (the owner's note n11), outside what the button itself shows: the trackpad (a light tap when
/// it went through, a firmer one when it was blocked, on a Force Touch trackpad only) and VoiceOver (its announcement).
@MainActor
package enum Feedback {
    /// Whether the trackpad taps (`appearance.haptics`).
    package static var taps = true

    /// Gives `outcome`.
    package static func give(_ outcome: ActionFeedback) {
        if taps {
            NSHapticFeedbackManager.defaultPerformer.perform(
                outcome.isDone ? .generic : .levelChange,
                performanceTime: .now
            )
        }
        guard let window = NSApp?.keyWindow ?? NSApp?.mainWindow else { return }
        NSAccessibility.post(
            element: window,
            notification: .announcementRequested,
            userInfo: [
                .announcement: outcome.announcement,
                .priority: NSAccessibilityPriorityLevel.high.rawValue
            ]
        )
    }

    /// A drop's answer: refused, it is said (a firmer tap, VoiceOver); taken, nothing more than what it moved.
    /// - Parameter taken: what the drop returned.
    /// - Returns: `taken`, for `performDrop` to return.
    package static func dropped(_ taken: Bool) -> Bool {
        if !taken { give(.blocked("It cannot be dropped here")) }
        return taken
    }
}
