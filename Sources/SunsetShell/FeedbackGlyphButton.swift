package import SwiftUI

/// A row's glyph button that says what its click did (the owner's note n11): for a moment its symbol becomes a check, or a
/// cross that shakes, with the trackpad's tap and VoiceOver's announcement (`Feedback`); its tooltip then says it too.
package struct FeedbackGlyphButton: View {
    let symbol: String
    let help: String
    let perform: () -> ActionFeedback
    @State private var cue: ActionFeedback?
    @State private var shakes = 0

    package init(symbol: String, help: String, perform: @escaping () -> ActionFeedback) {
        self.symbol = symbol
        self.help = help
        self.perform = perform
    }

    package var body: some View {
        RowGlyphButton(help: cue?.announcement ?? help) {
            let outcome = perform()
            Feedback.give(outcome)
            cue = outcome
            if !outcome.isDone { shakes += 1 }
            Task {
                try? await Task.sleep(for: ActionFeedback.shown)
                if cue == outcome { cue = nil }
            }
        } glyph: {
            Image(systemName: cue?.symbol ?? symbol)
                // The owner, 2026-11-18: no change of colour (the button's own), and quick.
                .contentTransition(.symbolEffect(.replace.downUp.wholeSymbol, options: .speed(3)))
                .keyframeAnimator(initialValue: 0.0, trigger: shakes) { glyph, offset in
                    glyph.offset(x: offset)
                } keyframes: { _ in
                    // A shake: no, no (blocked).
                    KeyframeTrack {
                        for x in [-3.0, 3, -2, 0] { SpringKeyframe(x, duration: 0.04) }
                    }
                }
        }
        .accessibilityLabel(help)
    }
}
