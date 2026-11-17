package import SunsetMetrics

/// The interface's tokens (docs/design/0003-design-system.md): a view names what a measure is for, never writes its number. Values are points.
/// The ones that are settings (`layout.*`) are read from the layout; the rest are fixed here.
package enum Design {
    /// The spacing scale: a 2 pt base, a 4 pt step. A value between two steps moves up to the next (docs/design/0002).
    package enum Space {
        /// Between the rows of a list; a title and its subtitle.
        package static let hair = 2.0
        /// Between the items of a bar.
        package static let xs = 4.0
        /// A container's inset around its leaves.
        package static let s = 6.0
        /// A row's leading padding.
        package static let m = 8.0
        /// A panel's padding.
        package static let l = 12.0
        /// Between groups in a panel.
        package static let xl = 16.0
        /// A sheet's padding.
        package static let xxl = 24.0
        /// The scale, smallest first.
        package static let scale = [hair, xs, s, m, l, xl, xxl]

        /// The step a measure belongs to: the smallest step not below it (more space, never less).
        package static func step(atLeast value: Double) -> Double { scale.first { $0 >= value } ?? xxl }
    }

    /// Two radii are chosen (the leaf, the small one); a container's is derived from what it holds, so that corners share a centre.
    package enum Radius {
        /// The system window's corner (`ConcentricRadius.standardWindow`, measured).
        package static let window = ConcentricRadius.standardWindow
        /// A row, a field, a control inside a container: `layout.tabRadius`.
        package static func leaf(_ layout: LayoutMetrics) -> Double { layout.tabRadius }
        /// A close button, a thumbnail, a badge: `layout.closeButtonRadius`.
        package static func small(_ layout: LayoutMetrics) -> Double { layout.closeButtonRadius }
        /// A container holding leaves of `leaf` radius at `inset` from its edge: the radius whose curve is concentric with theirs.
        package static func container(holding leaf: Double, inset: Double) -> Double { max(leaf, 0) + max(inset, 0) }
        /// A floating surface (a bar, a panel, a list of choices): leaves at the container inset.
        package static func surface(_ layout: LayoutMetrics) -> Double {
            container(holding: leaf(layout), inset: Space.s)
        }
    }

    package enum Size {
        /// A row's glyph: its frame, and the symbol in it.
        package static let glyphFrame = 18.0
        package static let glyphSymbol = 15.0
        /// A help popover's width: a short paragraph per line group, as VMRunner's (roadmap 0041 A).
        package static let helpPopoverWidth = 320.0
        /// Help's list of topics, and the width its text reads best at.
        package static let helpListWidth = 220.0
        package static let helpTextWidth = 560.0
        /// An icon button in a bar.
        package static let control = 24.0
        /// A field in a bar (the address field): a control and a point above and below for its text.
        package static let field = control + 2
        /// A bar: a field and the container inset around it, so that the field's corners nest in the bar's.
        package static let bar = field + 2 * Space.s
        /// The command bar's input.
        package static let fieldLarge = 48.0
        /// A row in a list of choices.
        package static let row = 36.0
        /// A one-line tab row: its glyph's ink as far from the top and the bottom as from the leading edge (n66, measured 9 pt). Two-line
        /// rows keep `layout.tabPaddingVertical`.
        /// The most of a page's dialog message that shows before it scrolls.
        package static let dialogMessage = 220.0
        package static let tabRow = 32.0
        /// A one-line row of the Favorites tree: as tall as a tab (owner, 2026-11-13, t227; it was 28, more compact, on 11-12).
        package static let favoriteRow = tabRow
        /// A topic's row in a list of the settings: shorter than a tab's.
        package static let topicRow = 26.0
        /// The list of sections and topics at the side of the settings' page, and the most the page's form is wide.
        package static let settingsList = 220.0
        package static let settingsPage = 720.0
        /// The dot of a document with edits that are not saved.
        package static let editedMark = 6.0
        /// A split tab's sub-row narrower than this shows its icon alone.
        package static let iconOnlyBelow = 56.0
    }

    /// The vertical padding of a sidebar row: a one-line row is `height` tall (the close button's square centred in it), a two-line row
    /// keeps the layout's padding.
    /// How far a frame of `outer` overhangs a centred `inner` on each side.
    package static func overhang(of outer: Double, over inner: Double) -> Double { (outer - inner) / 2 }

    /// The height of every one-line row: `height`, or what its close button and padding need when that is more. Set as the row's
    /// height (`View.rowHeight`), not left to its content: an emoji or a taller glyph made some rows taller (owner note n69).
    package static func oneLineHeight(_ layout: LayoutMetrics, height: Double) -> Double {
        max(height, layout.closeButtonSize + 2 * layout.tabPaddingVertical)
    }

    package static func rowPadding(_ layout: LayoutMetrics, lines: Int, height: Double) -> Double {
        lines > 1 ? layout.tabPaddingVertical : max(layout.tabPaddingVertical, (height - layout.closeButtonSize) / 2)
    }

    package enum Width {
        package static let popover = 320.0
        package static let panel = 360.0
        package static let sheet = 420.0
        package static let commandBar = 520.0
        /// The find bar's text field.
        package static let findField = 240.0
    }
}
