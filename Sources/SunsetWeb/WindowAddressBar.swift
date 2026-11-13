import AemiSDR
package import SunsetShell
package import SwiftUI

/// The address bar of a window (web step b): back, forward, reload (Stop while loading) and the address of the focused page. Hidden; it comes out
/// when the pointer reaches its edge of the pane area (or the page asks for an address), and goes after the pointer leaves it, unless it is typed in.
package struct WindowAddressBar: View {
    let content: WebContent
    let atTop: Bool
    /// The focused pane's card: the blur under the bar is cut to it.
    let card: PaneCardShape?
    /// Told when the bar comes out and goes (the split's margin follows it).
    var onOut: (Bool) -> Void = { _ in }
    @State private var shown = false
    @State private var hovering = false
    @State private var editing = false
    @Environment(\.surfaceStyle) private var surface

    package init(
        content: WebContent,
        atTop: Bool,
        card: PaneCardShape? = nil,
        onOut: @escaping (Bool) -> Void = { _ in }
    ) {
        self.content = content
        self.atTop = atTop
        self.card = card
        self.onOut = onOut
    }

    private var out: Bool { shown || editing || content.wantsAddress }

    package var body: some View {
        let frame = card?.frame
        ZStack(alignment: atTop ? .top : .bottom) {
            Color.clear
            Color.clear
                .frame(height: 6)
                .contentShape(.rect)
                .onHover { inside in if inside { shown = true } }
            if out {
                groups
                    .padding(Design.Space.m)
                    .onHover { inside in
                        hovering = inside
                        if !inside { hideSoon() }
                    }
                    .transition(.move(edge: atTop ? .top : .bottom).combined(with: .opacity))
            }
        }
        // Over the focused pane's card, its corners the groups' container; the blurs end at its edges.
        .frame(width: frame?.width, height: frame?.height)
        .containerShape(cardShape)
        .clipShape(cardShape)
        .offset(x: frame?.minX ?? 0, y: frame?.minY ?? 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .animation(.easeOut(duration: 0.18), value: out)
        // Asked for (a new page, Open Address): out until the pointer leaves it or typing ends, not just while the field asks.
        .onChange(of: content.wantsAddress, initial: true) { _, wanted in if wanted { shown = true } }
        .onChange(of: out, initial: true) { _, now in onOut(now) }
        .onDisappear { onOut(false) }
    }

    private var cardShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(cornerRadii: card?.radii ?? RectangleCornerRadii(), style: .continuous)
    }

    /// Back, forward and reload in one glass group at the leading edge; the address in another, as wide as the command bar at
    /// most, centred in the rest (owner, 2026-11-13: the system toolbar's way).
    private var groups: some View {
        let edge: Bool = atTop
        return GlassEffectContainer(spacing: Design.Space.m) {
            HStack(spacing: Design.Space.m) {
                HStack(spacing: Design.Space.xs) {
                    button("chevron.left", "Back", enabled: content.canGoBack) { content.goBack() }
                    button("chevron.right", "Forward", enabled: content.canGoForward) { content.goForward() }
                    if content.isLoading {
                        button("xmark", "Stop", enabled: true) { content.stopLoading() }
                    } else {
                        button("arrow.clockwise", "Reload", enabled: content.url != nil) { content.reload() }
                    }
                }
                .padding(.horizontal, Design.Space.s)
                .frame(height: Design.Size.bar)
                .barGroup(margin: Design.Space.m, top: edge)
                AddressField(content: content, place: edge ? .top : .bottom) { typing in
                    editing = typing
                    if !typing { hideSoon() }
                }
                .padding(.horizontal, Design.Space.s)
                .frame(height: Design.Size.bar)
                .barGroup(margin: Design.Space.m, top: edge)
                .frame(maxWidth: Design.Width.commandBar)
                .frame(maxWidth: .infinity)
            }
        }
    }

    /// Back, forward, reload: the sidebar's icon button, as tall as the field beside them and with its corner, so that every part of the bar
    /// is the same distance from the bar's edge (owner, 2026-11-12).
    private func button(_ symbol: String, _ help: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        SidebarIconButton(symbol: symbol, help: help, action: action)
            .environment(\.sidebarButtonMetrics, BarButton.metrics(surface, radius: Design.Size.field / 2))
            .disabled(!enabled)
    }

    /// Goes a moment after the pointer left, if it has not come back and nothing is being typed.
    private func hideSoon() {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            if !hovering, !editing { shown = false }
        }
    }
}
