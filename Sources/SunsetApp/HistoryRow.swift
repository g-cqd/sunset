import AppKit
import SunsetMetrics
import SunsetShell
import SunsetWeb
import SwiftUI

/// A page in the history panel: its title and address; a click opens it in the focused page, Cmd-click in a new tab; its menu.
struct HistoryRow: View {
    let entry: HistoryEntry
    let layout: LayoutMetrics
    /// Its title and its address.
    private static let lines = 2
    @State private var hovered = false

    var body: some View {
        // A sidebar row of a page that is not open: its glyph and two lines, no fill at rest (owner note n67).
        let shape = RoundedRectangle(cornerRadius: layout.tabRadius, style: .continuous)
        return HStack(spacing: GlyphSpacing.toText) {
            PaneGlyphView(glyph: .symbol("globe"))
            VStack(alignment: .leading, spacing: Design.Space.hair) {
                Text(entry.title.isEmpty ? AddressChoice.shortAddress(entry.url) : entry.title).lineLimit(1)
                Text(AddressChoice.shortAddress(entry.url))
                    .font(Design.Text.detail)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(.leading, layout.tabPaddingLeading)
        .padding(.trailing, layout.tabPaddingTrailing)
        .padding(.vertical, Design.rowPadding(layout, lines: Self.lines, height: Design.Size.tabRow))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(shape.fill(Color.primary.opacity(hovered ? Design.Fill.hover : 0)))
        .contentShape(shape)
        .animation(layout.smooth, value: hovered)
        .onHover { hovered = $0 }
        .onTapGesture { AppActions.shared.openFromHistory(entry.url, newTab: NSEvent.modifierFlags.contains(.command)) }
        .help(entry.url)
        .contextMenu {
            Button("Open") { AppActions.shared.openFromHistory(entry.url, newTab: false) }
            Button("Open in New Tab") { AppActions.shared.openFromHistory(entry.url, newTab: true) }
            Button("Copy Address") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(entry.url, forType: .string)
            }
            Divider()
            Button("Delete from History", role: .destructive) { AppHistory.shared?.delete(entry.url) }
        }
    }
}
