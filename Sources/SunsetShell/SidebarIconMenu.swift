package import SwiftUI

/// A menu drawn and behaving as a sidebar's glyph button (`SidebarIconButton`): the same face, hover, press and colour,
/// its items opened by a click. The documents' order and a new vault entry, beside the section's other buttons.
package struct SidebarIconMenu<Content: View>: View {
    let symbol: String
    let help: String
    @ViewBuilder let content: () -> Content
    @Environment(\.sidebarButtonMetrics) private var metrics

    package init(symbol: String, help: String, @ViewBuilder content: @escaping () -> Content) {
        self.symbol = symbol
        self.help = help
        self.content = content
    }

    package var body: some View {
        Menu {
            content()
        } label: {
            SidebarSymbol(name: symbol)
        }
        .menuStyle(.button)
        .buttonStyle(SidebarIconButtonStyle(metrics: metrics))
        .menuIndicator(.hidden)
        .fixedSize()
        .help(help)
        .accessibilityLabel(help)
    }
}
