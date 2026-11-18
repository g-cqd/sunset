import Foundation
import SunsetPane
import Testing

@testable import SunsetShell

/// Profiles (roadmap 0021, P-a; R4: "a web identity… a Space has one profile; several Spaces may share it"; decided by the
/// builder while the owner was away, ADR-0053). The Pinned grid is the profile's: the same in each of its Spaces, and
/// what is open there shows as open in all of them (the owner's note n80).
@MainActor
@Suite("Profiles")
struct ProfilesModelTests {
    private func spaces() -> SpacesModel { SpacesModel(makeFavorites: { FavoritesModel() }) }

    private func window(on spaces: SpacesModel, made: MadeContents) -> TabsModel {
        let tabs = TabsModel()
        tabs.makeContent = { descriptor in
            let content = FakeContent(descriptor)
            made.all.append(content)
            return content
        }
        tabs.show(space: spaces.spaces[0], in: spaces)
        return tabs
    }

    @Test
    func
        `there is always the first profile; others are made, named, and removed, their Spaces going back to the first`()
    {
        let spaces = spaces()
        let profiles = spaces.profiles
        #expect(
            profiles.profiles.map(\.profile.name) == ["Personal"] && profiles.profiles[0].profile.id == Profile.firstID
        )
        let work = profiles.add()
        #expect(work.profile.name == "Profile 2" && profiles.profiles.count == 2)
        profiles.rename(work, to: "  Work ")
        profiles.rename(work, to: "   ")
        #expect(work.profile.name == "Work")
        let space = spaces.add(from: spaces.spaces[0])
        spaces.setProfile(work.profile.id, for: space)
        #expect(space.space.profile == work.profile.id && profiles.profile(of: space.space) === work)
        #expect(profiles.profile(of: spaces.spaces[0].space) === profiles.profiles[0], "no profile named: the first")
        #expect(spaces.spaces(of: work).map(\.space.id) == [space.space.id])
        let erased = spaces.remove(profile: work)
        #expect(erased == work.profile.id && profiles.profiles.count == 1 && space.space.profile == nil)
        #expect(spaces.remove(profile: profiles.profiles[0]) == nil && profiles.profiles.count == 1, "the first stays")
    }

    @Test func `the Pinned grid is the profile's: the same in each of its Spaces, another in another profile's`() throws
    {
        let (spaces, made) = (spaces(), MadeContents())
        let window = window(on: spaces, made: made)
        let home = spaces.spaces[0]
        let second = spaces.add(from: home)
        let third = spaces.add(from: home)
        let work = spaces.profiles.add()
        spaces.setProfile(work.profile.id, for: third)
        window.newTab()
        let tab = try #require(window.workspace.selectedID)
        let entry = try #require(window.pin(item: tab))
        #expect(window.pinned === spaces.profiles.profiles[0].pinned)
        window.show(space: second)
        #expect(window.pinnedEntries.map(\.id) == [entry], "the same grid in the profile's other Space")
        #expect(window.pinnedEntries.first?.isOpen == true && !made.all[0].stopped, "and open there too (n80)")
        window.select(entry: entry)
        #expect(window.shownEntry?.id == entry && window.showsLive && made.all[0].visible)
        window.show(space: third)
        #expect(window.pinned === work.pinned && window.pinnedEntries.isEmpty, "another profile, another grid")
        #expect(!made.all[0].stopped && !made.all[0].visible, "what is open in the first profile runs on, unseen")
        // A profile removed: what was pinned in it is closed.
        window.newTab()
        let other = try #require(window.workspace.selectedID)
        _ = try #require(window.pin(item: other))
        _ = spaces.remove(profile: work)
        #expect(made.all[1].stopped && window.pinned === spaces.profiles.profiles[0].pinned)
    }

    @Test func `profiles are saved with their grids and come back; a Space of a profile that is gone is of the first`()
        throws
    {
        let (spaces, made) = (spaces(), MadeContents())
        let window = window(on: spaces, made: made)
        let work = spaces.profiles.add()
        spaces.profiles.rename(work, to: "Work")
        let space = spaces.add(from: spaces.spaces[0])
        spaces.setProfile(work.profile.id, for: space)
        window.show(space: space)
        window.newTab(.terminal(directory: "/work"))
        let tab = try #require(window.workspace.selectedID)
        _ = try #require(window.pin(item: tab))
        let saved = spaces.profiles.saved()
        #expect(saved.map(\.profile.name) == ["Personal", "Work"] && saved[1].pinned.favorites.entries.count == 1)
        let again = self.spaces()
        again.profiles.restore(saved, reopening: false)
        #expect(again.profiles.profiles.map(\.profile.name) == ["Personal", "Work"])
        #expect(again.profiles.profiles[1].pinned.favorites.entries.first?.isOpen == false)
        var orphan = Space(name: "Orphan")
        orphan.profile = UUID()
        #expect(again.profiles.profile(of: orphan) === again.profiles.profiles[0])
    }

    /// The owner, 2026-11-17: "Favorites become the profile's": one list, the same in every Space of the profile; what is
    /// open there shows as open in all of them (his note n80).
    @Test
    func
        `the Favorites are the profile's: the same in each of its Spaces, a new Space included; another profile's are its own`()
        throws
    {
        let (spaces, made) = (spaces(), MadeContents())
        let window = window(on: spaces, made: made)
        let home = spaces.spaces[0]
        window.newTab()
        let tab = try #require(window.workspace.selectedID)
        let entry = try #require(window.keep(item: tab))
        let second = spaces.add(from: home)
        #expect(second.favorites === home.favorites && home.favorites === spaces.profiles.first.favorites)
        window.show(space: second)
        #expect(window.favorites.favorites.entry(entry)?.isOpen == true && !made.all[0].stopped, "open here too (n80)")
        window.select(entry: entry)
        #expect(window.shownEntry?.id == entry && window.showsLive && made.all[0].visible)
        // A Space that is deleted takes no favourite with it: they are not its own.
        #expect(!second.holdsSomething)
        spaces.remove(second, movingTo: nil)
        #expect(home.favorites.favorites.entry(entry)?.isOpen == true && !made.all[0].stopped && window.space === home)
        // Another profile has its own; a Space given that profile shows them, and no longer the first's.
        let work = spaces.profiles.add()
        let third = spaces.add(from: home)
        window.show(space: third)
        window.select(entry: entry)
        spaces.setProfile(work.profile.id, for: third)
        #expect(third.favorites === work.favorites && work.favorites !== home.favorites && window.favorites.isEmpty)
        #expect(window.shownEntry == nil && !made.all[0].stopped && !made.all[0].visible, "left, not closed")
        // Saved with the profile, and back with it.
        let saved = spaces.profiles.saved()
        #expect(saved[0].favorites.favorites.entry(entry) != nil && saved[1].favorites.favorites.isEmpty)
        #expect(spaces.saved().allSatisfy { $0.favorites.favorites.isEmpty })
        let again = self.spaces()
        again.profiles.restore(saved, reopening: false)
        again.restore(spaces.saved(), reopening: false)
        #expect(again.spaces[0].favorites.favorites.entry(entry)?.isOpen == false)
        #expect(again.spaces[1].favorites === again.profiles.profiles[1].favorites)
    }
}

extension ProfilesModelTests {
    /// Roadmap 0050: a profile's own settings are kept with the session; a session of before's "Between runs" become them.
    @Test func `a profile's overrides are saved and read back, a session of before's choices carried over`() throws {
        var profile = Profile(name: "Work")
        profile.overrides = ["web.engine": #""DuckDuckGo""#]
        let back = try JSONDecoder().decode(Profile.self, from: JSONEncoder().encode(profile))
        #expect(back.overrides == ["web.engine": #""DuckDuckGo""#])
        let before = try JSONDecoder()
            .decode(
                Profile.self,
                from: Data(#"{"id":"\#(UUID())","name":"Old","keep":{"siteData":"clearOnQuit"}}"#.utf8)
            )
        #expect(before.overrides == ["web.keep.siteData": #""clearOnQuit""#])
    }
}
