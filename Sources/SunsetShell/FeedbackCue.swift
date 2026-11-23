package import SunsetShellModel

/// What a button keeps to show an outcome with `FeedbackGlyph`: shown for `ActionFeedback.shown`, said and felt.
@MainActor
package struct FeedbackCue {
    package private(set) var cue: ActionFeedback?
    package private(set) var shakes = 0

    package init() {}

    /// Shows `outcome`; `clear` is called after a moment to take it away.
    package mutating func show(_ outcome: ActionFeedback) {
        Feedback.give(outcome)
        cue = outcome
        if !outcome.isDone { shakes += 1 }
    }

    package mutating func clear(_ outcome: ActionFeedback) {
        if cue == outcome { cue = nil }
    }
}
