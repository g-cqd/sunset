public import Foundation

/// What the app had open, since Spaces: the Spaces in their one order, each with its tabs, the profiles with what is kept in each (the Pinned grid, the Favorites), and the windows
/// as views of the Spaces. Written when it quits and as things change, read at launch.
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
    /// The profiles, the first always there, each with its Pinned grid and its Favorites, which hold their panes before
    /// any Space does.
    public private(set) var profiles: [SavedProfile]
    /// The first profile's Pinned grid: all there was before profiles.
    public var pinned: SavedFavorites {
        profiles.first { $0.profile.isFirst }?.pinned ?? SavedFavorites()
    }

    /// - Parameters:
    ///   - spaces: the Spaces, in their order.
    ///   - views: the windows.
    ///   - pinned: the first profile's grid, when `profiles` does not hold the first (a file of before profiles).
    ///   - given: the profiles, each once.
    ///   - ownership: whose the Favorites and the Pinned grid are (`spaces.favorites`, `spaces.pinned`).
    public init(
        spaces: [SavedSpace],
        views: [SavedView],
        pinned: SavedFavorites = SavedFavorites(),
        profiles given: [SavedProfile] = [],
        ownership: Ownership = Ownership()
    ) {
        var known = Set<Profile.ID>()
        var profiles = given.filter { known.insert($0.profile.id).inserted }
        if !known.contains(Profile.firstID) { profiles.insert(SavedProfile(profile: .first, pinned: pinned), at: 0) }
        var seen = Set<Space.ID>()
        var own: [SavedSpace] = []
        for var space in spaces where own.count < Self.maximumSpaces && seen.insert(space.space.id).inserted {
            // Favorites are the profile's: a Space's own, of a file of before, go to its profile.
            if !ownership.favoritesBySpace, !space.favorites.favorites.isEmpty {
                let index = profiles.firstIndex { $0.profile.id == space.space.profile } ?? 0
                var all = profiles[index].favorites.favorites
                all.merge(space.favorites.favorites)
                let contents = profiles[index].favorites.contents
                    .merging(space.favorites.contents) { first, _ in first }
                profiles[index].favorites = SavedFavorites(favorites: all, contents: contents)
                space.favorites = SavedFavorites()
            }
            own.append(space)
        }
        // Each Space's: a profile's list, of a file written the other way, goes to its first Space.
        if ownership.favoritesBySpace { Self.giveFavorites(of: &profiles, to: &own) }
        // One grid for the app: the other profiles' grids, of a file written the other way, join the first's.
        if ownership.pinnedByApp { Self.joinPinned(of: &profiles) }
        self.profiles = profiles
        // What is kept holds its panes before any Space does.
        let grids = profiles.map(\.pinned.favorites) + profiles.map(\.favorites.favorites)
        var held = Set(grids.flatMap(\.livePanes))
        var kept: [SavedSpace] = []
        for var space in own {
            held = space.settle(taken: held)
            kept.append(space)
        }
        if kept.isEmpty { kept = [SavedSpace(space: Space())] }
        self.spaces = kept
        func entry(of view: SavedView) -> Favorites.NodeID {
            view.entry ?? Favorites.NodeID()
        }
        self.views = views.compactMap { view in
            guard let space = kept.first(where: { $0.space.id == view.space }) else { return nil }
            var view = view
            if let selected = view.selected, !space.tabs.items.contains(where: { $0.id == selected }) {
                view.selected = nil
            }
            let wanted = entry(of: view)
            let lists = grids + kept.map(\.favorites.favorites)
            let kept = lists.lazy.compactMap { $0.entry(wanted) }.first
            if view.entry != nil, kept?.isOpen != true { view.entry = nil }
            return view
        }
    }

    /// A session of before Spaces, or the windows of an app whose windows are one tab each: one Space with the windows'
    /// tabs one after the other in the windows' order and the Favorites; each window is a view of it with the selection it
    /// had.
    /// - Parameters:
    ///   - old: the windows and the Favorites, as versions 1 and 2 had them.
    ///   - named: what names the Space they become; unnamed, with a new id, for a file of before.
    ///   - ownership: whose the Favorites and the Pinned grid are.
    public init(_ old: SavedSession, space named: Space = Space(), ownership: Ownership = Ownership()) {
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
        self.init(spaces: [space], views: views, ownership: ownership)
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
            File(
                version: Self.version,
                spaces: spaces.map(Lossy.init),
                windows: views.map(Lossy.init),
                profiles: profiles
            )
        )
    }

    public init?(data: Data, ownership: Ownership = Ownership()) {
        guard let version = (try? JSONDecoder().decode(Versioned.self, from: data))?.version else { return nil }
        if version < Self.version {
            guard let old = SavedSession(data: data) else { return nil }
            self.init(old, ownership: ownership)
            return
        }
        guard version == Self.version, let file = try? JSONDecoder().decode(File.self, from: data) else { return nil }
        self.init(
            spaces: file.spaces.compactMap(\.value),
            views: file.windows.compactMap(\.value),
            pinned: file.pinned ?? SavedFavorites(),
            profiles: file.profiles?.compactMap(\.value) ?? [],
            ownership: ownership
        )
    }

    private struct Versioned: Decodable {
        let version: Int
    }

    private struct File: Codable {
        let version: Int
        let spaces: [Lossy<SavedSpace>]
        let windows: [Lossy<SavedView>]
        /// Of a file of before profiles: the one grid there was. Read as none when it cannot be read.
        let pinned: SavedFavorites?
        let profiles: [Lossy<SavedProfile>]?

        init(version: Int, spaces: [Lossy<SavedSpace>], windows: [Lossy<SavedView>], profiles: [SavedProfile]) {
            self.version = version
            self.spaces = spaces
            self.windows = windows
            self.pinned = nil
            self.profiles = profiles.map(Lossy.init)
        }

        private enum Key: String, CodingKey { case version, spaces, windows, pinned, profiles }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: Key.self)
            version = try container.decode(Int.self, forKey: .version)
            spaces = try container.decode([Lossy<SavedSpace>].self, forKey: .spaces)
            windows = try container.decode([Lossy<SavedView>].self, forKey: .windows)
            pinned = try? container.decodeIfPresent(SavedFavorites.self, forKey: .pinned)
            profiles = try? container.decodeIfPresent([Lossy<SavedProfile>].self, forKey: .profiles)
        }
    }
}
