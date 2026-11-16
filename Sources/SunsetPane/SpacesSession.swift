public import Foundation

/// What the app had open, since Spaces (roadmap 0021 step S-a; ADR-0045): the Spaces in their one order, each with its
/// Favorites and its tabs, and the windows as views of them. Written when it quits and as things change, read at launch.
///
/// Reading never fails the launch: a file that cannot be understood is no session, a damaged Space or view is left out.
/// What is read holds together: there is always a Space; a Space is there once; a pane is in one place (of two Spaces
/// that hold it the first keeps it, and a kept entry gives way to a tab); a view shows a Space that is there and selects a
/// tab that Space has, or an entry of it that is open.
public struct SpacesSession: Sendable, Equatable {
    /// 3 since Spaces. Versions 1 (windows only) and 2 (windows and Favorites) are read, as one Space.
    public static let version = 3
    /// The most Spaces read from a file; the rest is left out.
    public static let maximumSpaces = 64

    public private(set) var spaces: [SavedSpace]
    public private(set) var views: [SavedView]

    public init(spaces: [SavedSpace], views: [SavedView]) {
        var seen = Set<Space.ID>()
        var held = Set<PaneID>()
        var kept: [SavedSpace] = []
        for var space in spaces where kept.count < Self.maximumSpaces && seen.insert(space.space.id).inserted {
            held = space.settle(taken: held)
            kept.append(space)
        }
        if kept.isEmpty { kept = [SavedSpace(space: Space())] }
        self.spaces = kept
        self.views = views.compactMap { view in
            guard let space = kept.first(where: { $0.space.id == view.space }) else { return nil }
            var view = view
            if let selected = view.selected, !space.tabs.items.contains(where: { $0.id == selected }) {
                view.selected = nil
            }
            if let entry = view.entry, space.favorites.favorites.entry(entry)?.isOpen != true { view.entry = nil }
            return view
        }
    }

    /// A session of before Spaces, or the windows of an app whose windows are one tab each: one Space with the windows'
    /// tabs one after the other in the windows' order and the Favorites; each window is a view of it with the selection it
    /// had.
    /// - Parameters:
    ///   - old: the windows and the Favorites, as versions 1 and 2 had them.
    ///   - named: what names the Space they become; unnamed, with a new id, for a file of before.
    public init(_ old: SavedSession, space named: Space = Space()) {
        let id = named.id
        var tabs = Workspace()
        var contents: [PaneID: PaneDescriptor] = [:]
        var views: [SavedView] = []
        for window in old.windows {
            for item in window.workspace.items { tabs.insert(item, at: tabs.count) }
            contents.merge(window.contents) { first, _ in first }
            let entry = window.workspace.selectedEntry
            views.append(SavedView(space: id, selected: entry == nil ? window.workspace.selectedID : nil, entry: entry))
        }
        let space = SavedSpace(space: named, favorites: old.favorites, tabs: tabs, contents: contents)
        self.init(spaces: [space], views: views)
    }

    /// The tabs a window shows for `view`: its Space's, with the view's selection. Nil for a view of no Space.
    public func workspace(for view: SavedView) -> Workspace? {
        guard var tabs = spaces.first(where: { $0.space.id == view.space })?.tabs else { return nil }
        if let selected = view.selected { tabs.select(item: selected) }
        tabs.select(entry: view.entry)
        return tabs
    }

    // MARK: The file

    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        return try encoder.encode(
            File(version: Self.version, spaces: spaces.map(Lossy.init), windows: views.map(Lossy.init))
        )
    }

    public init?(data: Data) {
        guard let version = (try? JSONDecoder().decode(Versioned.self, from: data))?.version else { return nil }
        if version < Self.version {
            guard let old = SavedSession(data: data) else { return nil }
            self.init(old)
            return
        }
        guard version == Self.version, let file = try? JSONDecoder().decode(File.self, from: data) else { return nil }
        self.init(spaces: file.spaces.compactMap(\.value), views: file.windows.compactMap(\.value))
    }

    private struct Versioned: Decodable {
        let version: Int
    }

    private struct File: Codable {
        let version: Int
        let spaces: [Lossy<SavedSpace>]
        let windows: [Lossy<SavedView>]
    }

    /// A part that fails to read is nil instead of failing the whole file.
    private struct Lossy<Value: Codable>: Codable {
        let value: Value?
        init(_ value: Value) { self.value = value }
        init(from decoder: any Decoder) throws { value = try? Value(from: decoder) }
        func encode(to encoder: any Encoder) throws { try value?.encode(to: encoder) }
    }
}
