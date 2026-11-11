public import Foundation

/// What the app had open: its windows, and the Favorites they all show. Written when it quits, read at launch. Reading never fails the launch: a file
/// that cannot be understood is no session, a damaged window is left out, and Favorites that cannot be read are none.
public struct SavedSession: Sendable, Equatable {
    /// 2 since the Favorites; a file of version 1 (windows only) is still read.
    public static let version = 2
    public private(set) var windows: [SavedWindow]
    public private(set) var favorites: SavedFavorites

    /// A pane is live in one place: an entry that claims a pane a window has is kept as not open. A window does not select an entry that is not open,
    /// and a window with no tab that shows no entry is left out.
    public init(windows: [SavedWindow], favorites: SavedFavorites = SavedFavorites()) {
        var kept = favorites.favorites
        let inWindows = Set(windows.flatMap(\.workspace.allPanes))
        for entry in kept.entries where entry.open.map({ !inWindows.isDisjoint(with: $0.panes) }) == true {
            kept.unload(entry.id)
        }
        let open = Set(kept.entries.filter(\.isOpen).map(\.id))
        self.favorites = SavedFavorites(favorites: kept, contents: favorites.contents)
        self.windows = windows.compactMap { window in
            var window = window
            if let entry = window.workspace.selectedEntry, !open.contains(entry) { window.workspace.select(entry: nil) }
            return window.workspace.isEmpty && window.workspace.selectedEntry == nil ? nil : window
        }
    }

    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        let file = File(version: Self.version, windows: windows.map(Lossy.init), favorites: Lossy(favorites))
        return try encoder.encode(file)
    }

    public init?(data: Data) {
        guard let file = try? JSONDecoder().decode(File.self, from: data), (1 ... Self.version).contains(file.version)
        else { return nil }
        self.init(windows: file.windows.compactMap(\.value), favorites: file.favorites?.value ?? SavedFavorites())
    }

    private struct File: Codable {
        let version: Int
        let windows: [Lossy<SavedWindow>]
        let favorites: Lossy<SavedFavorites>?
    }

    /// A part that fails to read is nil instead of failing the whole file.
    private struct Lossy<Value: Codable>: Codable {
        let value: Value?
        init(_ value: Value) { self.value = value }
        init(from decoder: any Decoder) throws { value = try? Value(from: decoder) }
        func encode(to encoder: any Encoder) throws { try value?.encode(to: encoder) }
    }
}
