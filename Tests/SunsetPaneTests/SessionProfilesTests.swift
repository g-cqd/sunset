import Foundation
import Testing

@testable import SunsetPane

/// The session's profiles and their Pinned grids (P-a and P-b).
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

    /// Profiles: kept beside the Spaces, each with its Pinned grid. A file of before has one, the first.
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

    /// Favorites are the profile's. A file of before, where each Space had its own (a new Space had a copy of
    /// another's), gives each profile the Favorites of its Spaces, a copy once.
    @Test
    func `the Favorites are the profile's: those of its Spaces in a file of before are put together, a copy once`()
        throws
    {
        func kept(_ title: String, directory: String, open: Bool) throws -> (Favorites, Favorites.NodeID) {
            var favorites = Favorites()
            var tabs = Workspace()
            _ = tabs.add()
            let item = try #require(tabs.items.first)
            let made = favorites.keep(item, contents: [item.focused: .terminal(directory: directory)])
            let id = try #require(made)
            favorites.rename(id, to: title)
            if !open { favorites.unload(id) }
            return (favorites, id)
        }
        let (logs, original) = try kept("Logs", directory: "/var/log", open: false)
        // The second Space's: a copy of Logs, which is open there, and one of its own.
        var (second, copy) = try kept("Logs", directory: "/var/log", open: true)
        let (mail, own) = try kept("Mail", directory: "/mail", open: false)
        second.merge(mail)
        // A Space of another profile, with the same name kept: it is that profile's, not a copy.
        let work = SavedProfile(profile: Profile(name: "Work"))
        let (other, others) = try kept("Logs", directory: "/var/log", open: false)
        var first = space("Home", tabs: 1)
        first.favorites = SavedFavorites(favorites: logs)
        var next = space("Second", tabs: 0)
        next.favorites = SavedFavorites(favorites: second)
        var third = space("Third", tabs: 0)
        third.space.profile = work.profile.id
        third.favorites = SavedFavorites(favorites: other)
        let session = SpacesSession(spaces: [first, next, third], views: [], profiles: [work])
        #expect(session.spaces.allSatisfy { $0.favorites.favorites.isEmpty }, "none is the Space's any more")
        let personal = try #require(session.profiles.first { $0.profile.isFirst })
        #expect(personal.favorites.favorites.entries.map(\.title) == ["Logs", "Mail"])
        #expect(
            personal.favorites.favorites.entry(copy)?.isOpen == true,
            "of a copy and its original, the open one is kept"
        )
        #expect(personal.favorites.favorites.entry(original) == nil && personal.favorites.favorites.entry(own) != nil)
        let theirs = try #require(session.profiles.first { $0.profile.id == work.profile.id })
        #expect(theirs.favorites.favorites.entries.map(\.id) == [others])
        // Written and read again, it is the same, and nothing is put together twice.
        let read = try #require(SpacesSession(data: try session.encoded()))
        #expect(read == session && read.profiles[0].favorites.favorites.entries.count == 2)
    }
}
