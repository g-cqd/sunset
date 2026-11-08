import SunsetConfig

/// The measures of the sidebar's top, from `layout.*` and the margin `m` (`sidebar.padding`).
///
/// - The traffic lights' top left corner is the same distance from the window's top and from its leading edge: `m + lightsInset` (plus `floatingLightsExtra`
///   on the floating panel). The first tab starts `lightsGap` below them.
/// - The pin button's container is centred on the lights' row, and its trailing edge is the tabs' trailing edge.
struct SidebarHeader {
    /// The side of a traffic light button (the three are in a row).
    static let lightsSize = 14.0

    let layout: Configuration.Layout
    let margin: Double
    var floating = false

    private var extra: Double { floating ? layout.floatingLightsExtra : 0 }

    /// From the window's top left corner to the lights, the same in both directions.
    var lightsOrigin: Double { margin + layout.lightsInset + extra }

    /// The slot at the top of the sidebar's content: the lights' inset, the lights, and the gap.
    var height: Double { layout.lightsInset + Self.lightsSize + layout.lightsGap + extra }

    /// From the top of the slot to the top of the pin button's container, so that it is centred on the lights.
    var buttonTop: Double { layout.lightsInset + (Self.lightsSize - layout.pinButtonSize) / 2 + extra }
}
