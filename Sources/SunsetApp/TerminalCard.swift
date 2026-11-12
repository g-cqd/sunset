import SunsetConfig
import SunsetMetrics
import SunsetPane
import SunsetShell
import SunsetShellBridge
import SwiftUI

/// What the sidebar (or a split) does to a terminal: it becomes a card (rounded corners, a hairline stroke; the window's colour around it is the space the
/// caller leaves). The stroke is the one line there is: it turns to the accent colour when the card holds the keyboard in a split. Without the card the
/// terminal is left as it is and its background reaches the window's edges.
///
/// It is the same view tree either way, only with other numbers (radius, stroke opacity), so that the change animates and the AppKit terminal view under it
/// is kept: an `if` between two trees made SwiftUI throw the view away and make a new one at every pin and unpin (a flash).
struct TerminalCard: ViewModifier {
    var isCard: Bool
    /// The radius of the corners at the window's corners (concentric with them).
    var cornerRadius: Double
    /// Which corners are the window's; the others are next to the sidebar or another card and use `layout.innerCornerRadius`.
    var windowCorners = CornerSet.all
    var layout: Configuration.Layout
    var stroke = PaneStrokeStyle.hairline
    @Environment(\.accent) private var accent

    func body(content: Content) -> some View {
        let shape = UnevenRoundedRectangle(cornerRadii: radii, style: .continuous)
        return
            content
            .clipShape(shape)
            .overlay { shape.hairline(ShellSettings.Layout(layout)).opacity(stroke == .hairline ? 1 : 0) }
            .overlay { shape.hoverHairline(ShellSettings.Layout(layout)).opacity(stroke == .hovered ? 1 : 0) }
            .overlay {
                shape.focusHairline(ShellSettings.Layout(layout), accent: accent.color)
                    .opacity(stroke == .focused ? 1 : 0)
            }
    }

    private var radii: RectangleCornerRadii {
        Self.radii(isCard: isCard, outer: cornerRadius, windowCorners: windowCorners, layout: layout)
    }

    /// The radius of each corner: `outer` at the window's corners, `layout.innerCornerRadius` (never more than `outer`) where the card is next to the sidebar
    /// or to another card; none when it is not a card.
    static func radii(isCard: Bool, outer: Double, windowCorners: CornerSet, layout: Configuration.Layout)
        -> RectangleCornerRadii
    {
        guard isCard else { return RectangleCornerRadii() }
        let inner = min(layout.innerCornerRadius, outer)
        func radius(_ corner: CornerSet) -> Double { windowCorners.contains(corner) ? outer : inner }
        return RectangleCornerRadii(
            topLeading: radius(.topLeading),
            bottomLeading: radius(.bottomLeading),
            bottomTrailing: radius(.bottomTrailing),
            topTrailing: radius(.topTrailing)
        )
    }
}
