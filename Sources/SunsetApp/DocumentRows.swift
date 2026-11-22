import AppKit
import SunsetPane
import SunsetShell

/// The rows of the command bar that open a document: the file a typed path names, and the documents Sunset keeps whose
/// title matches.
@MainActor enum DocumentRows {
    /// The file at `path`: Return opens it in a tab (or shows the tab that has it).
    static func file(_ path: String, tabs: TabsModel) -> ChoiceRow {
        let actions = [
            ChoiceAction("Open", symbol: "doc.text") {
                tabs.bar = nil
                AppActions.shared.open(files: [path])
            },
            ChoiceAction("Show in Finder", symbol: "folder") {
                tabs.bar = nil
                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
            }
        ]
        return ChoiceRow(
            id: "file " + path,
            glyph: .symbol("doc.text"),
            title: "Open " + (path as NSString).lastPathComponent,
            subtitle: TabLabel.shortened((path as NSString).deletingLastPathComponent),
            accessory: "File",
            actions: ChoiceAction.keyed(actions)
        )
    }

    /// A document of the store: Return opens it as a tab.
    static func stored(_ document: ShelfDocument, tabs: TabsModel) -> ChoiceRow {
        let open = ChoiceAction("Open", symbol: document.kind.symbol) {
            tabs.bar = nil
            tabs.show(document: document.id)
        }
        return ChoiceRow(
            id: "document \(document.id)",
            glyph: .symbol(document.kind.symbol),
            title: document.title,
            accessory: "Document",
            actions: ChoiceAction.keyed([open])
        )
    }
}
