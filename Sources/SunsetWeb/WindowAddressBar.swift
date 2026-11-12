import SunsetShell
package import SwiftUI

/// The address bar of a window (web step b): back, forward, reload (Stop while loading) and the address of the focused page. Hidden; it comes out
/// when the pointer reaches its edge of the pane area (or the page asks for an address), and goes after the pointer leaves it, unless it is typed in.
package struct WindowAddressBar: View {
    let content: WebContent
    let atTop: Bool
    @State private var shown = false
    @State private var hovering = false
    @State private var editing = false
    @Environment(\.surfaceStyle) private var surface

    package init(content: WebContent, atTop: Bool) {
        self.content = content
        self.atTop = atTop
    }

    private var out: Bool { shown || editing || content.wantsAddress }

    package var body: some View {
        ZStack(alignment: atTop ? .top : .bottom) {
            Color.clear
            Color.clear
                .frame(height: 6)
                .contentShape(.rect)
                .onHover { inside in if inside { shown = true } }
            if out {
                bar
                    .padding(Design.Space.m)
                    .onHover { inside in
                        hovering = inside
                        if !inside { hideSoon() }
                    }
                    .transition(.move(edge: atTop ? .top : .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.18), value: out)
    }

    private var bar: some View {
        HStack(spacing: Design.Space.xs) {
            button("chevron.left", "Back", enabled: content.canGoBack) { content.goBack() }
            button("chevron.right", "Forward", enabled: content.canGoForward) { content.goForward() }
            if content.isLoading {
                button("xmark", "Stop", enabled: true) { content.stopLoading() }
            } else {
                button("arrow.clockwise", "Reload", enabled: content.url != nil) { content.reload() }
            }
            AddressField(content: content, place: atTop ? .top : .bottom) { typing in
                editing = typing
                if !typing { hideSoon() }
            }
        }
        .padding(.horizontal, Design.Space.s)
        .frame(height: Design.Size.bar)
        .surface(surface.shape)
    }

    /// Back, forward, reload: the sidebar's icon button, as tall as the field beside them and with its corner, so that every part of the bar
    /// is the same distance from the bar's edge (owner, 2026-11-12).
    private func button(_ symbol: String, _ help: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        SidebarIconButton(symbol: symbol, help: help, action: action)
            .environment(\.sidebarButtonMetrics, BarButton.metrics(surface))
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
