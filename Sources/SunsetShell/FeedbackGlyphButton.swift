package import SunsetRuntime
package import SwiftUI

/// A row's glyph button that says what its click did: for a moment its symbol becomes a check, or a cross that shakes,
/// with the trackpad's tap and VoiceOver's announcement (`Feedback`); its tooltip then says it too.
package struct FeedbackGlyphButton: View {
    @Environment(\.runtime) var runtime

    let symbol: String
    let help: String
    let perform: () -> ActionFeedback
    @State private var feedback = FeedbackCue()

    package init(symbol: String, help: String, perform: @escaping () -> ActionFeedback) {
        self.symbol = symbol
        self.help = help
        self.perform = perform
    }

    package var body: some View {
        RowGlyphButton(help: feedback.cue?.announcement ?? help) {
            let outcome = perform()
            feedback.show(outcome)
            runtime.task {
                await runtime.sleep(for: ActionFeedback.shown)
                feedback.clear(outcome)
            }
        } glyph: {
            FeedbackGlyph(symbol: symbol, cue: feedback.cue, shakes: feedback.shakes)
        }
        .accessibilityLabel(help)
    }
}
