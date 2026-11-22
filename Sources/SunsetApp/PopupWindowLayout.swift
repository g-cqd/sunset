import Foundation
import SunsetConfig
import SunsetMetrics
import SunsetShell
import SunsetShellBridge

/// The measures of a pop-up window: the window's own margin around one card (`sidebar.padding`, the window of tabs'
/// margin around its card), round at every corner, and a strip above it holding the traffic lights where the window of
/// tabs has them and Open in ‹Space›.
struct PopupWindowLayout {
    /// Around the card, and its corners: the window of tabs' own (`PaneAreaGeometry`, one card with the sidebar docked).
    let margin: Double
    let cardRadius: Double

    init(_ configuration: Configuration, windowRadius: Double = ConcentricRadius.standardWindow) {
        let geometry = PaneAreaGeometry.make(
            fullScreen: false,
            docked: true,
            panes: 1,
            measures: .init(
                margin: configuration.sidebar.padding,
                paneGap: configuration.layout.paneGap,
                windowRadius: windowRadius,
                terminalRadius: configuration.layout.terminalRadius,
                innerCornerRadius: configuration.layout.innerCornerRadius
            )
        )
        margin = geometry.inset
        cardRadius = geometry.outerRadius
    }

    /// The strip's controls: the window bar's glass groups, as the system toolbar's (owner, 2026-11-20: "your buttons don't
    /// look really native"), compact ("it's really big": "the compact version but with the paradigms of the native ones"),
    /// `capsuleGap` from the window's top and the card.
    static let capsuleHeight = 22.0
    static let capsuleGap = Design.Space.s
    /// The room the extensions' buttons have in the strip: three, or two and the puzzle piece.
    static let extensionsWidth = 3 * 28.0 + 2 * Design.Space.xs
    /// The room at a capsule's ends: its radius, so the text is as far from the curve as from the straight edges.
    static let capsuleEnd = capsuleHeight / 2
    /// A peek's page when it opens (a link from another app asks for no size).
    static let peekPage = CGSize(width: 960, height: 720)

    /// The strip above the card: the controls and their gap above and below.
    var strip: Double {
        Self.capsuleHeight + 2 * Self.capsuleGap
    }

    /// The lights' middle, from the window's top: the strip's.
    var lightsMiddle: Double {
        strip / 2
    }

    /// From the window's side edge to the lights: as far as their top is from the window's top.
    var lightsX: Double {
        strip / 2 - Design.TabCapsules.lightWidth / 2
    }

    /// The room the lights take from the strip's controls' edge (`capsuleGap` in from the window's): from where they are, not
    /// the tab bar's ("a weird spacing between the address bar and the traffic lights"). The strip's spacing then leaves
    /// `capsuleGap` between them and the next control, as between two controls (seen 2026-11-20: 13 pt, now 6).
    var lightsRoom: Double {
        lightsX + 2 * Design.System.lightsPitch + Design.TabCapsules.lightWidth - Self.capsuleGap
    }

    /// The window that shows a page of `page`'s size.
    func windowSize(forPage page: CGSize) -> CGSize {
        CGSize(width: page.width + 2 * margin, height: page.height + strip + margin)
    }
}
