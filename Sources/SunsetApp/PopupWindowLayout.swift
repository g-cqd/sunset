import Foundation
import SunsetConfig
import SunsetMetrics
import SunsetShell
import SunsetShellBridge

/// The measures of a pop-up window (task t132): the window's own margin around one card (`sidebar.padding`, the window of
/// tabs' margin around its card: the owner, 2026-11-20, "the margin does not respect the usual one of window"), round at every
/// corner, and a strip above it holding the traffic lights where the window of tabs has them and Open in ‹Space›.
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

    /// Open in ‹Space›'s capsule, and its gap to the window's top and to its side edge (the same: the owner, 2026-11-20, "the
    /// capsule seems too far from the edge").
    static let capsuleHeight = 22.0
    static let capsuleGap = 6.0
    /// The room at the capsule's ends: its radius, so the text is as far from the curve as from the straight edges.
    static let capsuleEnd = capsuleHeight / 2

    /// The strip above the card: the capsule and its gap above and below.
    var strip: Double {
        Self.capsuleHeight + 2 * Self.capsuleGap
    }

    /// The lights' middle, from the window's top: the strip's (the owner: "traffic lights seem to not be vertically centered").
    var lightsMiddle: Double {
        strip / 2
    }

    /// From the window's side edge to the lights: as far as their top is from the window's top.
    var lightsX: Double {
        strip / 2 - SidebarHeader.lightsSize / 2
    }

    /// The window that shows a page of `page`'s size.
    func windowSize(forPage page: CGSize) -> CGSize {
        CGSize(width: page.width + 2 * margin, height: page.height + strip + margin)
    }
}
