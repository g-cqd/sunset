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
    @Binding var opensAtOnce: Bool
    @State private var reveal = HoverReveal(hideDelay: .milliseconds(350))

    private var side: Configuration.Side { settings.sidebar.side }
    private var margin: Double { settings.sidebar.padding }
    private var radius: Double {
        settings.layout.panelRadius ?? ConcentricRadius.inner(outer: windowRadius, inset: margin)
    }

    var body: some View {
        ZStack(alignment: side.alignment) {
            Color.clear
                .frame(width: settings.layout.revealStripWidth)
                .contentShape(.rect)
                .onHover { inside in pointer(inside) }
            if shown { panel.transition(.move(edge: side.moveEdge).combined(with: .opacity)) }
        }
        .frame(maxHeight: .infinity, alignment: side.alignment)
        .onAppear {
            guard opensAtOnce else { return }
            opensAtOnce = false
            // Out until the pointer is seen on the panel: it leaves after its delay when it is not.
            reveal.pointer(inside: true, at: .now)
            pointer(false)
        }
    }

    private var panel: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return TabSidebar(tabs: tabs, settings: settings, floating: true)
            // The panel ends where the docked column does, and its tabs are as wide and as far from the edge as the docked ones: pinning moves nothing.
            .frame(width: settings.sidebar.width - margin)
            .frame(maxHeight: .infinity)
            .background { SidebarBackdrop(look: panelLook) }
            .clipShape(shape)
            .overlay { shape.hairline(settings.layout) }
            .overlay(alignment: side == .left ? .trailing : .leading) {
                // Centred between the end of the tabs and the panel's edge, so it ends at the edge.
                SidebarResizeHandle(
                    width: settings.sidebar.width,
                    hitWidth: SidebarHandle.hitWidth(
                        docked: false,
                        wanted: settings.layout.resizeHandleWidth,
                        tabSideInset: settings.layout.floatingTabSideInset
                    ),
                    side: side
                )
            }
            .padding(side.edge, margin)
            .padding(.vertical, margin)
            .onHover { inside in pointer(inside) }
    }

    /// The panel is always glass (it floats over the terminal and has to be readable there), with the window's blur, glass style and tint.
    private var panelLook: SidebarLook {
        var look = SidebarLook(settings)
        look.material = .glass
        return look
    }

    private func pointer(_ inside: Bool) {
        let now = ContinuousClock.now
        reveal.hideDelay = .seconds(settings.layout.hideDelay)
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
        if visible != shown { withAnimation(settings.layout.smooth) { shown = visible } }
    }
}
