import SunsetMetrics
package import SwiftUI

/// The app's one look for a small button that is not a control of its own (n110: buttons in Passwords and the library
/// showed nothing under the pointer or pressed): nothing at rest; a rounded fill under the pointer; a darker one, and a
/// slightly smaller label, pressed. A glyph or a short title; the window's corner and the tab's close button's size.
package struct QuietButtonStyle: ButtonStyle {
    @Environment(\.surfaceStyle) private var surface
    /// Room on either side of the label: none for a glyph (a square, as a tab's close button), some for words.
    let inset: Double

    package init(inset: Double = Design.Space.xs) {
        self.inset = inset
    }

    package func makeBody(configuration: Configuration) -> some View {
        QuietButtonFace(
            label: configuration.label,
            pressed: configuration.isPressed,
            layout: surface.layout,
            inset: inset
        )
    }
}

extension ButtonStyle where Self == QuietButtonStyle {
    /// `QuietButtonStyle`.
    package static var quiet: QuietButtonStyle {
        QuietButtonStyle()
    }

    /// `QuietButtonStyle` for a glyph alone: a square.
    package static var quietGlyph: QuietButtonStyle {
        QuietButtonStyle(inset: 0)
    }
}
