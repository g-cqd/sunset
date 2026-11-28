internal import Foundation
internal import SunsetPane

/// Files opened in this window: from the Open panel, a drop, Finder, the command bar.
extension TabsModel {
    /// Opens each of `paths` in a tab of its own, the last one shown. A file this window already shows is shown where it
    /// is, however its path is written.
    package func open(files paths: [String]) {
        for path in paths {
            let wanted = Self.onePath(path)
            // Opened lately, for the Library's list: a private window leaves no such trace.
            if !isPrivateWindow { shelf.noteFile(wanted) }
            let pane = workspace.allPanes.first { pane in
                content(pane)?.descriptor.documentFile.map(Self.onePath) == wanted
            }
            if let pane, let item = workspace.item(containing: pane) {
                select(item: item.id)
                focus(pane)
            } else {
                newTab(.forFile(wanted))
            }
        }
    }

    /// The documents this window lists (the Library, the panel opposite the tabs, the command bar): the store's, then the
    /// files opened lately. None in a private window: their names are the person's.
    package var listedDocuments: [ShelfDocument] {
        isPrivateWindow ? [] : shelf.list() + shelf.files()
    }

    /// The documents the bar offers for what is typed: the listed ones whose title holds every word, but for the ones a tab
    /// of this window shows (the tab is listed). None for nothing typed, and none when the bar picks a tab to split.
    package func barDocuments(_ bar: CommandBar) -> [ShelfDocument] {
        guard bar.purpose == .search, !bar.query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let stored = Set(workspace.allPanes.compactMap { document(in: $0) })
        let files = Set(workspace.allPanes.compactMap { content($0)?.descriptor.documentFile.map(Self.onePath) })
        return ShelfDocument.matching(bar.query, in: listedDocuments)
            .filter { document in
                document.file.map { !files.contains(Self.onePath($0)) } ?? !stored.contains(document.id)
            }
    }

    /// Whether a tab of this window shows the file at `path`.
    package func shows(file path: String) -> Bool {
        let wanted = Self.onePath(path)
        return workspace.allPanes.contains { content($0)?.descriptor.documentFile.map(Self.onePath) == wanted }
    }

    private static func onePath(_ path: String) -> String {
        URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath().path
    }
}
