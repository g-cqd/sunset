import SwiftUI

extension TabSidebar {
    /// The scrolled rows fade out at the top as soon as they move, over at most `Design.Space.xl`: rows at rest are untouched. At
    /// the bottom they fade out above the app's bar.
    var fade: some View {
        fade(scrolled: scrolledBy)
    }

    /// The same for a list scrolled by `scrolled` (the neighbour's while sliding between Spaces: at its top).
    func fade(scrolled: Double) -> some View {
        VStack(spacing: 0) {
            LinearGradient(
                gradient: .end(from: .clear, to: .black, fading: fadesEnds),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: min(scrolled, Design.Space.xl))
            Color.black
            if bottomBar != nil {
                // Gone by the bar's top: under its buttons nothing is drawn (seen 2026-11-17: a row showed through them
                // when the fade ran over the bar's whole height).
                LinearGradient(
                    gradient: .end(from: .black, to: .clear, fading: fadesEnds),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: Design.Space.xl)
                Color.clear.frame(height: bottomInset)
            }
        }
    }
}
