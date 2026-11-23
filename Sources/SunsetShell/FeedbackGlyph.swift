package import SwiftUI

/// The one way a click's outcome is shown on a glyph (n111: copying looked different in every place): for a moment the
/// glyph becomes a check, or a cross that shakes (`ActionFeedback`), then its own again.
package struct FeedbackGlyph: View {
    let symbol: String
    let cue: ActionFeedback?
    let shakes: Int

    package init(symbol: String, cue: ActionFeedback?, shakes: Int) {
        self.symbol = symbol
        self.cue = cue
        self.shakes = shakes
    }

    package var body: some View {
        Image(systemName: cue?.symbol ?? symbol)
            // No change of colour (the button's own), and quick.
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
}
