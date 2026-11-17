import Foundation
import Testing

@testable import SunsetPane

/// The session's profiles and their Pinned grids (roadmap 0021, P-a and P-b; ADR-0050, ADR-0053).
@Suite("The session's profiles and what is pinned")
struct SessionProfilesTests {
    private func space(_ name: String, tabs count: Int) -> SavedSpace {
        var workspace = Workspace()
        for _ in 0 ..< count { workspace.add(after: .end) }
        return SavedSpace(space: Space(name: name), tabs: workspace)
    }

    /// The Pinned grid is the app's (one profile until there are several): kept beside the Spaces.
    @Test func `what is pinned is kept beside the Spaces, and holds its panes before any Space does`() throws {
        var pinned = Favorites()
        var tabs = Workspace()
        _ = tabs.add()
        let item = try #require(tabs.items.first)
        let made = pinned.keep(item, contents: [item.focused: .terminal(directory: "/pinned")])
        let entry = try #require(made)
        // A Space that also lists that tab gives it up.
        let thief = SavedSpace(
            space: Space(name: "Thief"),
            tabs: tabs,
            contents: [item.focused: .terminal(directory: "/x")]
        )
        let session = SpacesSession(spaces: [thief], views: [], pinned: SavedFavorites(favorites: pinned))
        #expect(session.spaces[0].tabs.isEmpty && session.pinned.favorites.entry(entry)?.isOpen == true)
        let read = try #require(SpacesSession(data: try session.encoded()))
        #expect(read == session && read.pinned.favorites.entries.count == 1)
        #expect(read.pinned.favorites.entry(entry)?.home.contents[item.focused]?.directory == "/pinned")
        #expect(SpacesSession(spaces: [], views: []).pinned.favorites.isEmpty)
    }

    /// Profiles (ADR-0053): kept beside the Spaces, each with its Pinned grid. A file of before has one, the first.
    @Test func `the profiles are kept with their grids; a file with none has the first, with what was pinned`() throws {
        var pinned = Favorites()
        var tabs = Workspace()
        _ = tabs.add()
        let made = pinned.keep(try #require(tabs.items.first), contents: [:])
        _ = try #require(made)
        let work = SavedProfile(profile: Profile(name: "Work"), pinned: SavedFavorites(favorites: pinned))
        let first = SavedProfile(profile: Profile(id: Profile.firstID, name: "Me"))
        let session = SpacesSession(spaces: [space("A", tabs: 1)], views: [], profiles: [first, work, work])
        #expect(session.profiles.map(\.profile.name) == ["Me", "Work"], "a profile is there once")
        let read = try #require(SpacesSession(data: try session.encoded()))
        #expect(read == session && read.profiles[1].pinned.favorites.entries.count == 1)
        // Before profiles: what was pinned is the first profile's.
        let old = SpacesSession(spaces: [], views: [], pinned: SavedFavorites(favorites: pinned))
        #expect(
            old.profiles.map(\.profile.id) == [Profile.firstID] && old.profiles[0].pinned.favorites.entries.count == 1
        )
        #expect(old.pinned.favorites.entries.count == 1)
        #expect(SpacesSession(spaces: [], views: []).profiles.map(\.profile.name) == ["Personal"])
    }
}
