/// The measures of the sidebar's top, from `layout.*` and the margin `m` (`sidebar.padding`).
///
/// - The traffic lights' top left corner is the same distance from the window's top and from its leading edge: `m + lightsInset` (plus `floatingLightsExtra`
///   on the floating panel). The first tab starts `lightsGap` below them.
/// - The pin button's container is centred on the lights' row, and its trailing edge is the tabs' trailing edge.
package struct SidebarHeader {
    /// The side of a traffic light button (the three are in a row).
    package static let lightsSize = 14.0

    package let layout: ShellSettings.Layout
    package let margin: Double
    package var floating = false

    package init(layout: ShellSettings.Layout, margin: Double, floating: Bool = false) {
        self.layout = layout
        self.margin = margin
        self.floating = floating
    }

    private var extra: Double { floating ? layout.floatingLightsExtra : 0 }

    /// From the window's top left corner to the lights, the same in both directions.
    package var lightsOrigin: Double { margin + layout.lightsInset + extra }

    /// The slot at the top of the sidebar's content: the lights' inset, the lights, and the gap.
    package var height: Double { layout.lightsInset + Self.lightsSize + layout.lightsGap + extra }

    /// The docked pin button's container: its top is the terminal card's top (the sidebar's top margin) and its middle the lights', so it is as tall as twice
    /// the distance between the two, and square.
    package var dockedButtonSize: Double {
        2 * (layout.lightsInset + extra + Self.lightsSize / 2) - 2 * layout.hairlineWidth
    }

    /// Its height: from the card's top to `tabSpacing` above the first tab, the space the tabs have between them. Not square: the width keeps the tabs' edge, the
    /// height keeps the tabs' rhythm.
    package var dockedButtonHeight: Double { height - layout.tabSpacing - layout.hairlineWidth }

    /// A filled container flush with a hairline looks larger than the line: it is drawn one stroke width inside on every side (the hairline is drawn inside its
    /// shape, so its edge is the card's edge).
    package var dockedButtonInset: Double { layout.hairlineWidth }

    /// From the top of the slot to the top of the pin button's container, so that it is centred on the lights.
    package var buttonTop: Double { layout.lightsInset + (Self.lightsSize - layout.pinButtonSize) / 2 + extra }
}
