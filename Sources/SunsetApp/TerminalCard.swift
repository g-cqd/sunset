import SunsetConfig
import SwiftUI

/// What the sidebar does to the terminal: it becomes a card (the window's colour around it, rounded corners, a hairline stroke). Without the docked sidebar
/// the terminal is left as it is and its background reaches the window's edges.
///
/// It is the same view tree either way, only with other numbers (margin, radius, stroke opacity), so that the change animates and the AppKit terminal view
/// under it is kept: an `if` between two trees made SwiftUI throw the view away and make a new one at every pin and unpin (a flash).
struct TerminalCard: ViewModifier {
    var isCard: Bool
    var margin: Double
    var cornerRadius: Double
    var layout: Configuration.Layout

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: isCard ? cornerRadius : 0, style: .continuous)
        return
            content
            .clipShape(shape)
            .overlay { shape.hairline(layout).opacity(isCard ? 1 : 0) }
            .padding(isCard ? margin : 0)
    }
}
