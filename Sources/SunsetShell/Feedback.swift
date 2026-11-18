import AppKit

/// Says back what a click did (the owner's note n11), outside what the button itself shows: the trackpad (a light tap when
/// it went through, a firmer one when it was blocked, on a Force Touch trackpad only) and VoiceOver (its announcement).
@MainActor
package enum Feedback {
    /// Gives `outcome`.
    package static func give(_ outcome: ActionFeedback) {
        NSHapticFeedbackManager.defaultPerformer.perform(
            outcome.isDone ? .generic : .levelChange,
            performanceTime: .now
        )
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
}
