import AppKit

/// Says back what a click did, outside what the button itself shows: the trackpad (a light tap when it went through, a
/// firmer one when it was blocked, on a Force Touch trackpad only) and VoiceOver (its announcement).
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

    /// A drag snapped onto a new place that takes it: the alignment tick, the lightest the trackpad has.
    package static func snapped() {
        guard taps else { return }
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
    }

    /// Where a drag over the sidebar would land, the last time it was asked: a tick when it changes (`DropFeel`).
    package static var sidebarFeel = DropFeel<String>()

    /// A drop's answer: refused, it is said (a firmer tap, VoiceOver); taken, nothing more than what it moved.
    /// - Parameter taken: what the drop returned.
    /// - Returns: `taken`, for `performDrop` to return.
    package static func dropped(_ taken: Bool) -> Bool {
        if !taken { give(.blocked("It cannot be dropped here")) }
        return taken
    }
}
