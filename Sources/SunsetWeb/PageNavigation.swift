package import SunsetShell
package import SwiftUI

/// Back and forward of a page in one glass group (reload is in its address field): the window bar's leading group, and the tab
/// bar's after the window's buttons.
package struct PageNavigation: View {
    let content: WebContent
    /// Its blur falls from the top edge (at the bottom: up).
    var atTop = true
    /// In the tab bar's row of capsules: the field's flat look, not glass (it floats over nothing).
    var flat = false
    @Environment(\.surfaceStyle) private var surface

    package init(content: WebContent, atTop: Bool = true, flat: Bool = false) {
        self.content = content
        self.atTop = atTop
        self.flat = flat
    }

    package var body: some View {
        if flat {
            // The tab bar's row: each button its own circle.
            HStack(spacing: Design.Space.s) {
                TabCapsuleButton(symbol: "chevron.left", help: "Back") { content.goBack() }
                    .disabled(!content.canGoBack)
                TabCapsuleButton(symbol: "chevron.right", help: "Forward") { content.goForward() }
                    .disabled(!content.canGoForward)
            }
        } else {
            glass
        }
    }

    private var glass: some View {
        HStack(spacing: Design.Space.xs) {
            button("chevron.left", "Back", enabled: content.canGoBack) { content.goBack() }
            button("chevron.right", "Forward", enabled: content.canGoForward) { content.goForward() }
        }
        .frame(height: Design.Size.bar)
        .barGroup(margin: Design.Space.m, top: atTop)
    }

    /// The sidebar's icon button, as tall as the group: a capsule of the same shape.
    private func button(_ symbol: String, _ help: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        SidebarIconButton(symbol: symbol, help: help, action: action)
            .environment(\.sidebarButtonMetrics, BarButton.group(surface))
            .disabled(!enabled)
    }
}
