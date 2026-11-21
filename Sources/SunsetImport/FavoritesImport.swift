import Foundation
public import SunsetPane

/// Another browser's bookmarks as Sunset's Favorites (roadmap 0111 A).
public enum FavoritesImport {
    /// The name a folder without one gets.
    public static let unnamedFolder = "Imported"
    /// The addresses an entry may start from: Sunset opens web pages and files; a bookmarklet (`javascript:`) runs a
    /// script in whichever page is open, and a browser's own pages (`chrome:`, `about:`) are not Sunset's.
    static let schemes: Set<String> = ["http", "https", "file"]

    /// The Favorites `nodes` make: folders as folders, links as entries that are not open, each a web page at its address.
    /// A folder deeper than Favorites nest gives what it holds to the deepest one there may be; past
    /// `Favorites.maximumNodes` the rest is left out.
    public static func favorites(from nodes: [BookmarkNode]) -> (favorites: Favorites, report: ImportReport) {
        var budget = Favorites.maximumNodes
        var leftOut = 0
        var favorites = Favorites()
        favorites.append(made(nodes, budget: &budget, leftOut: &leftOut))
        let links = favorites.entries.count
        return (favorites, ImportReport(links: links, folders: favorites.count - links, leftOut: leftOut))
    }

    /// The address a link opens; nil when it is not one Sunset opens.
    static func address(_ written: String) -> URL? {
        let trimmed = written.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased(), schemes.contains(scheme) else {
            return nil
        }
        return scheme == "file" || url.host?.isEmpty == false ? url : nil
    }

    /// Favorites' nodes for `nodes`, as many as `budget` allows (a dissolved folder spends one it gives back to nobody:
    /// the limit is approached from below).
    private static func made(_ nodes: [BookmarkNode], budget: inout Int, leftOut: inout Int) -> [Favorites.Node] {
        var result: [Favorites.Node] = []
        for node in nodes {
            guard budget > 0 else {
                leftOut += node.count
                continue
            }
            switch node {
                case .folder(let folder):
                    budget -= 1
                    let name = folder.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    let children = made(folder.children, budget: &budget, leftOut: &leftOut)
                    result.append(Favorites.newFolder(named: name.isEmpty ? unnamedFolder : name, children: children))
                case .link(let link):
                    guard let url = address(link.address) else {
                        leftOut += 1
                        continue
                    }
                    let pane = PaneID()
                    let home = Favorites.Home(layout: .pane(pane), focused: pane, contents: [pane: .page(url)])
                    guard let entry = Favorites.newEntry(home: home, title: link.title) else {
                        leftOut += 1
                        continue
                    }
                    budget -= 1
                    result.append(entry)
            }
        }
        return result
    }
}
