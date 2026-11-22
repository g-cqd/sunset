import SunsetShell
import SwiftUI

/// A menu in a Library section's title row, drawn as its glyph buttons are: the documents' order, a new vault entry.
struct SectionMenuButton<Content: View>: View {
    let symbol: String
    let label: String
    let size: CGSize
    @ViewBuilder let content: () -> Content

    var body: some View {
        Menu {
            content()
        } label: {
            SidebarSymbol(name: symbol, filled: false)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .foregroundStyle(.secondary)
        .fixedSize()
        .frame(width: size.width, height: size.height)
        .help(label)
        .accessibilityLabel(label)
    }
}
