import SunsetConfig
import SwiftUI

/// What the sidebar (or a split) does to a terminal: it becomes a card (rounded corners, a hairline stroke; the window's colour around it is the space the
/// caller leaves). The stroke is the one line there is: it turns to the accent colour when the card holds the keyboard in a split. Without the card the
/// terminal is left as it is and its background reaches the window's edges.
///
/// It is the same view tree either way, only with other numbers (radius, stroke opacity), so that the change animates and the AppKit terminal view under it
/// is kept: an `if` between two trees made SwiftUI throw the view away and make a new one at every pin and unpin (a flash).
struct TerminalCard: ViewModifier {
    var isCard: Bool
    var cornerRadius: Double
    var layout: Configuration.Layout
    /// This card has the keyboard and shares the window with others: its stroke is the accent colour.
    var isFocused = false

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: isCard ? cornerRadius : 0, style: .continuous)
        return
            content
            .clipShape(shape)
            .overlay { shape.hairline(layout).opacity(isCard && !isFocused ? 1 : 0) }
            .overlay { shape.focusHairline(layout).opacity(isCard && isFocused ? 1 : 0) }
    }
}
