import SwiftUI

/// What the sidebar does to the terminal: it becomes a card (the window's colour around it, rounded corners, a hairline stroke). Without the sidebar
/// the terminal is left as it is and its background reaches the window's edges.
struct TerminalCard: ViewModifier {
    var isCard: Bool
    var margin: Double
    var cornerRadius: Double

    @ViewBuilder func body(content: Content) -> some View {
        if isCard {
            let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            content
                .clipShape(shape)
                .overlay { shape.hairline() }
                .padding(margin)
        } else {
            content
        }
    }
}
