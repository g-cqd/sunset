import SunsetConfig
import SunsetHost
import SwiftUI

/// The sidebar when it hides (`sidebar.autoHide`): a thin strip along the window's leading edge, and, while the pointer is on it or on what it revealed, a
/// floating glass panel over the terminal that holds the tabs and the traffic lights (the window puts the lights at the panel's top left while it shows,
/// and hides them when it does not). The panel goes 350 ms after the pointer leaves it (`HoverReveal`).
struct FloatingSidebar: View {
    let tabs: TabsModel
    let settings: Configuration
    let windowRadius: Double
    @Binding var shown: Bool
    @State private var reveal = HoverReveal(hideDelay: .milliseconds(350))

    /// Where the traffic lights are in the panel, from its top left corner, and the room they take: the list starts below them.
    static let lightsInset = 8.0
    static let lightsHeight = 14.0

    private var margin: Double { settings.sidebar.padding }
    private var radius: Double { ConcentricRadius.inner(outer: windowRadius, inset: margin) }

    var body: some View {
        ZStack(alignment: .leading) {
            Color.clear
                .frame(width: 10)
                .contentShape(.rect)
                .onHover { inside in pointer(inside) }
            if shown { panel.transition(.move(edge: .leading).combined(with: .opacity)) }
        }
        .frame(maxHeight: .infinity, alignment: .leading)
    }

    private var panel: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return TabSidebar(
            tabs: tabs,
            settings: settings,
            topInset: Self.lightsInset + Self.lightsHeight + Self.lightsInset,
            lightsMiddle: Self.lightsInset + Self.lightsHeight / 2
        )
        .frame(width: settings.sidebar.width - 2 * margin)
        .frame(maxHeight: .infinity)
        .background { SidebarBackdrop(look: panelLook) }
        .clipShape(shape)
        .overlay { shape.hairline() }
        .padding(margin)
        .onHover { inside in pointer(inside) }
    }

    /// Glass, whatever `sidebar.material` says (the docked sidebar has none by default; a floating one needs something to be read over), with the shared tint.
    private var panelLook: SidebarLook {
        var look = SidebarLook(settings)
        look.material = .glass
        return look
    }

    private func pointer(_ inside: Bool) {
        let now = ContinuousClock.now
        reveal.pointer(inside: inside, at: now)
        update(at: now)
        if let at = reveal.hidesAt {
            Task {
                try? await Task.sleep(until: at, clock: .continuous)
                update(at: .now)
            }
        }
    }

    private func update(at time: ContinuousClock.Instant) {
        let visible = reveal.isShown(at: time)
        if visible != shown { withAnimation(.easeInOut(duration: 0.18)) { shown = visible } }
    }
}
