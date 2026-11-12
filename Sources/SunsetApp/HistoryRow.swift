import AppKit
import SunsetShell
import SunsetWeb
import SwiftUI

/// A page in the history panel: its title and address; a click opens it in the focused page, Cmd-click in a new tab; its menu.
struct HistoryRow: View {
    let entry: HistoryEntry
    let radius: Double
    @State private var hovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(entry.title.isEmpty ? AddressChoice.shortAddress(entry.url) : entry.title).lineLimit(1)
            Text(AddressChoice.shortAddress(entry.url))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: radius, style: .continuous).fill(Color.primary.opacity(hovered ? 0.07 : 0))
        )
        .contentShape(.rect)
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
