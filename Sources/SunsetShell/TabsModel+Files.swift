internal import Foundation
internal import SunsetPane

/// Files opened in this window (R6, roadmap 0023 step M-f): from the Open panel, a drop, Finder, the command bar.
extension TabsModel {
    /// Opens each of `paths` in a tab of its own, the last one shown. A file this window already shows is shown where it
    /// is, however its path is written.
    package func open(files paths: [String]) {
        for path in paths {
            let wanted = Self.onePath(path)
            let pane = workspace.allPanes.first { pane in
                content(pane)?.descriptor.documentFile.map(Self.onePath) == wanted
            }
            if let pane, let item = workspace.item(containing: pane) {
                select(item: item.id)
                focus(pane)
            } else {
                newTab(.document(file: wanted))
            }
        }
    }

    /// The documents of the store the bar offers for what is typed: the ones whose title holds every word, but for the ones
    /// a tab of this window shows (the tab is listed). None for nothing typed, and none when the bar picks a tab to split.
    package func barDocuments(_ bar: CommandBar) -> [ShelfDocument] {
        guard bar.purpose == .search, !bar.query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let shown = Set(workspace.allPanes.compactMap { document(in: $0) })
        return ShelfDocument.matching(bar.query, in: shelf.list()).filter { !shown.contains($0.id) }
    }

    private static func onePath(_ path: String) -> String {
        URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath().path
    }
}
