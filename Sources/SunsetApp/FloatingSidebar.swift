import SunsetConfig
import SunsetHost
import SunsetMetrics
import SunsetRuntime
import SunsetShell
import SunsetShellBridge
import SwiftUI

/// The sidebar when it hides (`sidebar.autoHide`): a thin strip along the window's leading edge, and, while the pointer is on it or on what it revealed, a
/// floating glass panel over the terminal that holds the tabs and the traffic lights (the window puts the lights at the panel's top left while it shows,
/// and hides them when it does not). The panel goes 350 ms after the pointer leaves it (`HoverReveal`).
struct FloatingSidebar: View {
    @Environment(\.runtime) var runtime

    let tabs: TabsModel
    let settings: Configuration
    let windowRadius: Double
    @Binding var shown: Bool
    @Binding var opensAtOnce: Bool
    /// The field at the top, as the docked sidebar has it.
    var accessory: AnyView?
    /// Out whatever the pointer does: its field is typed in, or the page's address was asked for.
    var held = false
    @State private var reveal = HoverReveal(hideDelay: .milliseconds(350))

    private var side: Configuration.Side {
        settings.sidebar.side
    }
    private var margin: Double {
        settings.sidebar.padding
    }
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
        .onChange(of: held, initial: true) { _, now in
            let time = runtime.uptime()
            reveal.hold(now, at: time)
            look(at: time)
        }
        .onAppear {
            guard opensAtOnce else { return }
            opensAtOnce = false
            // Out until the pointer is seen on the panel: it leaves after its delay when it is not.
            reveal.pointer(inside: true, at: runtime.uptime())
            pointer(false)
        }
    }

    private var panel: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        let library = LibrarySidebar.extraWidth(tabs, ShellSettings(settings), floating: true)
        return AppSidebar(
            tabs: tabs,
            configuration: settings,
            floating: true,
            panelRadius: radius,
            accessory: accessory
        )
        // The panel ends where the docked column does, and its tabs are as wide and as far from the edge as the docked ones: pinning moves
        // nothing. The Library's rail widens it.
        .frame(width: settings.sidebar.width - margin + library)
        .frame(maxHeight: .infinity)
        .background {
            SidebarBackdrop(look: panelLook)
                .contentShape(.rect)
                .gesture(WindowDragGesture())
        }
        .clipShape(shape)
        .overlay { shape.hairline(ShellSettings.Layout(settings.layout)) }
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

    /// The panel is drawn as every floating surface is (`window.material`, design 0003 §6), with the window's blur, glass style and tint.
    private var panelLook: SidebarLook {
        SidebarLook(settings)
    }

    private func pointer(_ inside: Bool) {
        let now = runtime.uptime()
        reveal.hideDelay = .seconds(settings.layout.hideDelay)
        reveal.pointer(inside: inside, at: now)
        look(at: now)
    }

    /// Shown or not as of `now`, and looked at again when it is due to hide.
    private func look(at now: Duration) {
        update(at: now)
        if let at = reveal.hidesAt {
            runtime.task {
                await runtime.sleep(until: at)
                update(at: runtime.uptime())
            }
        }
    }

    private func update(at time: Duration) {
        let visible = reveal.isShown(at: time)
        if visible != shown { withAnimation(settings.layout.smooth) { shown = visible } }
    }
}
