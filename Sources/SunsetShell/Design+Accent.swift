import SwiftUI

extension Design {
    /// Where the accent comes from (`appearance.accent`): the colour that marks a selection, a focus, a filled control.
    package enum Accent: Sendable, Equatable {
        /// The system's accent (System Settings).
        case system
        /// Sunset's: `appearance.tint.color`, as sRGB bytes.
        case color(red: UInt8, green: UInt8, blue: UInt8)
        /// Shades of the scheme: light grey on dark, dark grey on light.
        case neutral

        /// The accent for a choice and the tint. "sunset" without a tint, or with one too dark or too light to stand out on a window
        /// (relative luminance outside `readable`), is the system's (owner, 2026-11-12).
        package static func resolve(_ choice: String, tint: [UInt8]?) -> Self {
            switch choice {
                case "sunset":
                    guard let tint, tint.count == 3, readable.contains(luminance(tint)) else { return .system }
                    return .color(red: tint[0], green: tint[1], blue: tint[2])
                case "neutral": return .neutral
                default: return .system
            }
        }

        /// The luminances a tint may have to be an accent.
        package static let readable = 0.08 ... 0.85

        /// WCAG's relative luminance of an sRGB colour (0 black, 1 white).
        package static func luminance(_ rgb: [UInt8]) -> Double {
            let linear = rgb.prefix(3)
                .map { byte -> Double in
                    let value = Double(byte) / 255
                    return value <= 0.040_45 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
                }
            guard linear.count == 3 else { return 0 }
            return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]
        }

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

        /// The neutral accent's greys, and the luminance above which ink on an accent is dark.
        package enum Neutral {
            package static let onDark = 0.85
            package static let onLight = 0.25
            package static let darkInkAbove = 0.5
        }
    }
}
