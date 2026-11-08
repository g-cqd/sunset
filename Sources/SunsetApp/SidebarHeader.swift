/// The measures of the sidebar, all derived from one unit, the margin `m` (`sidebar.padding`), so that the spaces between the parts look alike.
///
/// - A tab's highlight is `2m - 2` from the window's leading edge and from the terminal (`m` of margin outside, `m` inside the sidebar).
/// - The traffic lights' top left corner is the same distance from the window's top and from its leading edge, `m + 6`, and the first tab starts 10 pt
///   below them. Measured (screenshot): the first circle's visible edge is 12 pt from the top and 12 pt from the leading edge.
/// - The pin button's container is as high as the lights' row is centred, and its trailing edge is the tabs' trailing edge.
enum SidebarHeader {
    /// The side of a traffic light button (the three are in a row).
    static let lightsSize = 14.0
    /// The side of the pin button's container.
    static let buttonSize = 24.0

    /// From the sidebar's own top left corner (inside its outer margin) to the lights: 6 pt, close to the system's own inset.
    static let lightsInset = 6.0

    /// From the window's top left corner to the lights, the same in both directions: the outer margin plus `lightsInset` (12 pt with the default margin).
    static func lightsOrigin(margin: Double, floating: Bool = false) -> Double {
        margin + lightsInset + (floating ? floatingExtra : 0)
    }

    /// The floating panel has its lights this much further from the top and the leading edge than the docked sidebar.
    static let floatingExtra = 2.0

    /// The space between the lights and the first tab: a little more than between two tabs, because the lights are a separate group.
    static let lightsGap = 10.0

    /// The slot at the top of the sidebar's content: the lights' inset, the lights, and the gap.
    static func height(margin: Double, floating: Bool = false) -> Double {
        lightsInset + lightsSize + lightsGap + (floating ? floatingExtra : 0)
    }

    /// From the top of the slot to the top of the pin button's container, so that it is centred on the lights.
    static func buttonTop(margin: Double, floating: Bool = false) -> Double {
        lightsInset + (lightsSize - buttonSize) / 2 + (floating ? floatingExtra : 0)
    }
}
