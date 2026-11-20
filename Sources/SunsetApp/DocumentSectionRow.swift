import AppKit
import SunsetMetrics
import SunsetPane
import SunsetShell
import SwiftUI

/// A document in a section of a sidebar: its title, and when it was last changed; a click shows it where it already is in
/// the window's tabs, else opens it as a new tab; Cmd-click opens another tab on it; it is dragged as a tab is.
struct DocumentSectionRow: View {
    let tabs: TabsModel
    let document: ShelfDocument
    let layout: LayoutMetrics
    /// Under a day's heading: the time is enough.
    let byDay: Bool
    /// Its title and its date.
    private static let lines = 2
    @State private var hovered = false

    private var isOpen: Bool {
        if let file = document.file { return tabs.shows(file: file) }
        return tabs.workspace.allPanes.contains { tabs.document(in: $0) == document.id }
    }

    /// When it was changed; for a file opened lately, when it was opened and the folder it is in.
    private var changed: String {
        let when =
            byDay
            ? document.modified.formatted(date: .omitted, time: .shortened)
            : document.modified.formatted(date: .abbreviated, time: .shortened)
        guard let file = document.file else { return when }
        return when + "  " + TabLabel.shortened((file as NSString).deletingLastPathComponent)
    }

    private func open() {
        if let file = document.file { tabs.open(files: [file]) } else { tabs.show(document: document.id) }
    }

    var body: some View {
        HStack(spacing: GlyphSpacing.toText) {
            PaneGlyphView(glyph: .symbol(document.kind.symbol))
            VStack(alignment: .leading, spacing: Design.Space.hair) {
                Text(document.title).lineLimit(1)
                Text(changed).font(Design.Text.detail).foregroundStyle(.secondary).lineLimit(1)
            }
        }
        .modifier(
            LibraryRowFrame(
                layout: layout,
                lines: Self.lines,
                fill: hovered ? Design.Fill.openHover : (isOpen ? Design.Fill.open : 0),
                hovered: $hovered
            )
        )
        .onTapGesture {
            if NSEvent.modifierFlags.contains(.command), document.file == nil { openInNewTab() } else { open() }
        }
        .onDrag {
            // A file is dragged as a file (onto a terminal its path is typed); a document of the store as a tab.
            guard let file = document.file else { return tabs.itemProvider(for: .document(document.id)) }
            return NSItemProvider(object: URL(fileURLWithPath: file) as NSURL)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        // A press through accessibility (VoiceOver, Voice Control) does not reach a tap gesture on a combined element: seen in
        // the app, where pressing the row did nothing (diary 2026-11-15).
        .accessibilityAction { open() }
        .contextMenu {
            // In a new tab with Option, for a document with no file (task t135).
            Button("Open") { open() }
                .modifierKeyAlternate(.option) {
                    if document.file == nil { Button("Open in New Tab") { openInNewTab() } }
                }
            if let file = document.file {
                Button("Show in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: file)])
                }
                Divider()
                Button("Remove from This List") { tabs.shelf.forgetFile(file) }
            } else {
                Divider()
                Button("Delete", role: .destructive) { tabs.delete(document: document.id) }
            }
        }
    }

    private func openInNewTab() {
        tabs.openTab(
            document: document.id,
            at: (tabs.workspace.selectedIndex ?? tabs.workspace.count - 1) + 1,
            show: true
        )
    }
}
