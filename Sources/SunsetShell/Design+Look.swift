package import SwiftUI

extension Design {
    /// Fills and lines, as opacities of the primary colour unless said otherwise.
    package enum Fill {
        package static let faint = 0.04
        package static let hover = 0.07
        package static let pressed = 0.16
        /// A dimming layer (Apple's figure for one under clear glass).
        package static let scrim = 0.35
        /// The accent line of the focused card.
        package static let focusLine = 0.85
    }

    /// A shadow: black at an opacity, a blur radius, a drop.
    package struct Shadow: Sendable, Equatable {
        package let opacity: Double
        package let radius: Double
        package let y: Double
        /// Under a popover or a panel attached to a bar.
        package static let popover = Self(opacity: 0.25, radius: 14, y: 6)
        /// Under a surface floating over the window (the command bar).
        package static let float = Self(opacity: 0.3, radius: 24, y: 8)
    }

    /// The sizes of SF Symbols that are not in a row's glyph slot.
    package enum Symbol {
        package static let badge = 9.0
        package static let row = 13.0
        package static let bar = 15.0
        package static let hero = 28.0
    }

    /// Text, by the system's styles only.
    package enum Text {
        package static let title = Font.headline
        package static let body = Font.body
        package static let secondary = Font.callout
        package static let detail = Font.caption
        package static let mono = Font.body.monospaced()
    }

    /// How a surface is drawn (`window.material` governs every surface: design 0003 §6).
    package enum Surface: String, Sendable, Equatable, CaseIterable {
        case glass, material, opaque, fill
    }

    /// Where the accent comes from (`appearance.accent`).
    package enum Accent: Sendable, Equatable {
        /// The system's accent (System Settings).
        case system
        /// Sunset's: `appearance.tint.color`, as sRGB bytes.
        case color(red: UInt8, green: UInt8, blue: UInt8)
        /// Shades of the scheme: near white on dark, near black on light.
        case neutral

        /// The accent for a choice and the tint: "sunset" without a tint is the system's.
        package static func resolve(_ choice: String, tint: [UInt8]?) -> Self {
            switch choice {
                case "sunset":
                    guard let tint, tint.count == 3 else { return .system }
                    return .color(red: tint[0], green: tint[1], blue: tint[2])
                case "neutral": return .neutral
                default: return .system
            }
        }
    }

    /// Measures the grid gets wrong to the eye, each named, with its reason and its measurement (design 0003 §4).
    package enum Optical {
        /// A row's glyph frame to its text: the glyph's ink as far from the text as from the row's edge (8.5 pt, measured on a selected
        /// sidebar row; n63). With the glyph's 15 pt ink in an 18 pt frame, 7.
        package static let glyphToText = 7.0
        /// A filled container flush with a hairline looks larger than the line: it is drawn one stroke inside (`SidebarHeader`).
        package static func insideHairline(_ hairlineWidth: Double) -> Double { hairlineWidth }
        /// The download card's illustration: a one-off size, not a symbol step.
        package static let downloadIllustration = 64.0
    }
}
