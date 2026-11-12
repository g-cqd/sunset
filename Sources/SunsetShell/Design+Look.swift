package import SwiftUI

extension Design {
    /// Fills and lines, as opacities of the primary colour unless said otherwise.
    package enum Fill {
        package static let faint = 0.04
        package static let hover = 0.07
        package static let pressed = 0.16
        /// A row that is open (every tab, an open kept entry), at rest and under the pointer; a kept entry that is not open has no fill and is
        /// not dimmed (owner, 2026-11-12).
        package static let open = 0.06
        /// The selected row (primary), at rest and under the pointer; dimmer while the window is not the active one.
        package static let selected = 0.14
        package static let selectedHover = 0.2
        package static let selectedInactive = 0.08
        package static let selectedInactiveHover = 0.12
        /// A row among several selected, and a place a drag would drop into (the accent at these opacities).
        package static let marked = 0.18
        package static let markedHover = 0.26
        package static let target = 0.22
        /// A busy tab whose close was clicked once (red), at rest and under the pointer; its outline; its close button.
        package static let armed = 0.2
        package static let armedHover = 0.28
        package static let armedLine = 0.65
        package static let armedButton = 0.7
        package static let armedButtonHover = 0.85
        /// The accent pressed: a selected choice row while the mouse is down.
        package static let accentPressed = 0.8
        /// Secondary text on the accent (a selected choice row's subtitle).
        package static let inkSecondary = 0.75
        /// Behind the command bar, over the window (black).
        package static let backdrop = 0.18
        /// A separator drawn as a fill (primary), and a divider made fainter.
        package static let separator = 0.18
        package static let fainterDivider = 0.5
        /// A note's own background over the window.
        package static let noteBackground = 0.6
        /// A choice that does not apply (the icon picker's colours with no symbol, its categories while searching).
        package static let notApplicable = 0.4
        /// A folder's own icon while it is collapsed.
        package static let collapsedIcon = 0.7
        /// A field's fill (primary at this opacity), and a private page's dark one (black).
        package static let field = 0.08
        package static let darkField = 0.7
        package static let openHover = 0.1
        /// A floating surface's colour fill is at least this opaque, so that its text reads over a page; the window keeps the tint's own alpha
        /// (owner, 2026-11-12).
        package static let floatingMinimum = 0.85
        /// Under the window's address bar's surface (black), for its text over a light page (owner, 2026-11-13).
        package static let barShade = 0.3
        /// A dimming layer (Apple's figure for one under clear glass).
        package static let scrim = 0.35
        /// The accent line of the focused card.
        package static let focusLine = 0.85
    }

    /// An opaque surface over the window: the window's colour, a little lighter, so that it reads as raised.
    package enum Raised {
        package static let lighten = 0.06
        package static var color: Color { Color(nsColor: .windowBackgroundColor).mix(with: .white, by: lighten) }
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
        /// A kind's picture in the kind chooser.
        package static let large = 22.0
        /// A tiny mark beside a title (the built-in bar's star).
        package static let mark = 7.0
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

    /// Where the accent comes from (`appearance.accent`).
    /// Measures that come from the system's own parts, not the grid: each says where it comes from.
    package enum System {
        /// From one traffic light's left edge to the next's, as AppKit places the standard window buttons (23 pt, measured on macOS 26).
        package static let lightsPitch = 23.0
        /// The room the three traffic lights take at a window's leading edge with no title bar (their inset, three buttons and two gaps:
        /// 8 + 14 + 9 + 14 + 9 + 14, rounded up), kept clear for the built-in tab bar at the top.
        package static let lightsClearance = 72.0
        /// From the window's top to the command bar: under the title bar's height (52) and a hairline's room, where Spotlight sits.
        package static let commandBarTop = 56.0
    }

    /// Lines drawn from `layout.hairline*`: stronger for a drop line, the hover outline's factor and its cap.
    package enum Line {
        package static let stronger = 1.5
        package static let hover = 2.5
        package static let hoverCap = 0.45
    }

    /// Measures the grid gets wrong to the eye, each named, with its reason and its measurement (design 0003 §4).
    package enum Optical {
        /// A row's glyph frame to its text: the glyph's ink as far from the text as from the row's edge (8.5 pt, measured on a selected
        /// sidebar row; n63). With the glyph's 15 pt ink in an 18 pt frame, 7.
        package static let glyphToText = 7.0
        /// A filled container flush with a hairline looks larger than the line: it is drawn one stroke inside (`SidebarHeader`).
        package static func insideHairline(_ hairlineWidth: Double) -> Double { hairlineWidth }
        /// The address field's leading mark (the lock, the private eye) to its text: the mark's ink as far from the text as from the field's
        /// edge (10 pt, measured on the field; the row rule).
        package static let fieldGlyphToText = 6.5
        /// A folder's initial: its size and how far below the symbol's centre it sits, so that it is centred in the folder's body under its
        /// tab (owner, 2026-11-12, from `r3-initials.png`).
        package static let folderInitialSize = 6.5
        package static let folderInitialDrop = 1.75
        /// A file's symbol in a download's thumbnail: half the thumbnail.
        package static let thumbnailSymbol = 0.5
        /// The per-site rows in Settings > Websites start under the site's name (to confirm by the owner: not measured).
        package static let siteRowsIndent = 26.0
        /// The download card's illustration: a one-off size, not a symbol step.
        package static let downloadIllustration = 64.0
    }
}
