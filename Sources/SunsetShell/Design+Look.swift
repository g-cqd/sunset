package import SwiftUI

extension Design {
    /// An opaque surface over the window: the window's colour, a little lighter, so that it reads as raised.
    package enum Raised {
        package static let lighten = 0.06
        package static var color: Color {
            Color(nsColor: .windowBackgroundColor).mix(with: .white, by: lighten)
        }
    }

    /// A shadow: black at an opacity, a blur radius, a drop.
    package struct Shadow: Sendable, Equatable {
        package let opacity: Double
        package let radius: Double
        package let y: Double
        /// Under a popover or a panel attached to a bar.
        package static let popover = Self(opacity: 0.25, radius: 14, y: 6)
    }

    /// The sizes of SF Symbols that are not in a row's glyph slot.
    package enum Symbol {
        package static let badge = 9.0
        package static let row = 13.0
        package static let bar = 15.0
        package static let hero = 28.0
        /// A kind's picture in the kind chooser.
        package static let large = 22.0
        /// A tiny mark beside a title (the built-in bar's star).
        package static let mark = 7.0
        /// The weight of a row's and a bar's control symbols (close, cup, sound, microphone, camera): one for all.
        package static let weight = Font.Weight.semibold
    }

    /// Text, by macOS's built-in text styles only (Apple's HIG, Typography: macOS has no Dynamic Type; its styles, measured on
    /// macOS 27.0.1: headline 13 semibold, body 13, callout 12, subheadline 11, footnote and caption 10, title3 15, title2 17).
    package enum Text {
        /// A panel's or a sheet's title.
        package static let title = Font.headline
        /// A row's title, a field's text.
        package static let body = Font.body
        /// Secondary text in a panel; the built-in bar's titles.
        package static let secondary = Font.callout
        /// A small label (a glyph's initial).
        package static let small = Font.subheadline
        /// A row's second line, a subtitle, a hint.
        package static let detail = Font.caption
        /// A count on a corner of a button (an extension's badge).
        package static let badge = Font.system(size: 8, weight: .bold)
        /// The command bar's input.
        package static let input = Font.title2
        /// A heading on an empty page (title3).
        package static let heading = Font.title3
        /// The smallest text (caption2): the built-in bar's details.
        package static let tiny = Font.caption2
        package static let mono = Font.body.monospaced()
    }

    /// How a surface is drawn (`window.material` governs every surface: design 0003 §6).
    package enum Surface: String, Sendable, Equatable, CaseIterable {
        case glass, material, opaque, fill
    }

    /// Lines drawn from `layout.hairline*`: stronger for a drop line, the hover outline's factor and its cap.
    package enum Line {
        package static let stronger = 1.5
        package static let hover = 2.5
        package static let hoverCap = 0.45
        /// A place a drag could be dropped, outlined from the start of the drag (the owner, 2026-11-17): the dash and the gap.
        package static let dropDash: [CGFloat] = [4, 3]
        /// The outline's strength, as an opacity of the accent: there, not loud; full under the pointer.
        package static let dropOutline = 0.55
    }
}
