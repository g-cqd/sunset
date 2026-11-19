import AppKit
import SwiftUI

extension Design.Accent {
    /// The colour, and the ink drawn on it (a selected row's text), in a scheme.
    package func style(dark: Bool) -> AccentStyle {
        switch self {
            case .system: AccentStyle(color: Color(nsColor: .controlAccentColor), ink: .white)
            case .neutral:
                dark
                    ? AccentStyle(color: Color(white: Neutral.onDark), ink: .black)
                    : AccentStyle(color: Color(white: Neutral.onLight), ink: .white)
            case .color(let red, let green, let blue):
                AccentStyle(
                    color: Color(
                        .sRGB,
                        red: Double(red) / 255,
                        green: Double(green) / 255,
                        blue: Double(blue) / 255
                    ),
                    ink: Self.luminance([red, green, blue]) > Neutral.darkInkAbove ? .black : .white
                )
        }
    }
}
