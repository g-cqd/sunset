import SwiftUI

extension TabSidebar {
    /// The scrolled rows fade out at the top as soon as they move, over at most `Design.Space.xl`: rows at rest are untouched. At
    /// the bottom they fade out above the app's bar.
    var fade: some View {
        VStack(spacing: 0) {
            LinearGradient(gradient: .eased(from: .clear, to: .black), startPoint: .top, endPoint: .bottom)
                .frame(height: min(scrolledBy, Design.Space.xl))
            Color.black
            if bottomBar != nil {
                // Gone by the bar's top: under its buttons nothing is drawn (seen 2026-11-17: a row showed through them
                // when the fade ran over the bar's whole height).
                LinearGradient(gradient: .eased(from: .black, to: .clear), startPoint: .top, endPoint: .bottom)
                    .frame(height: Design.Space.xl)
                Color.clear.frame(height: bottomInset)
            }
        }
    }
}
