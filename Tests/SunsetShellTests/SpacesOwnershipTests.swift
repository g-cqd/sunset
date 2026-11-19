import Foundation
import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// Whose the Favorites and the Pinned grid are (roadmap 0044; the owner, 2026-11-17): by default each Space has its own
/// Favorites and each profile its grid; a setting shares the Favorites in a profile, another the grid in the app.
@MainActor
@Suite("Whose the Favorites and the grid are")
struct SpacesOwnershipTests {
    private func spaces(_ ownership: SpacesSession.Ownership) -> SpacesModel {
        SpacesModel(ownership: ownership, makeFavorites: { FavoritesModel() })
    }

    private func folder(_ name: String, in favorites: FavoritesModel) {
        favorites.edit { _ = $0.addFolder(named: name) }
    }

    @Test func `by Space: each has its own, kept with it, through a change of profile, and given on delete`() throws {
        let spaces = spaces(SpacesSession.Ownership(favoritesBySpace: true))
        let home = spaces.spaces[0]
        folder("Home's", in: home.favorites)
        let other = spaces.add(from: home)
        #expect(other.favorites !== home.favorites && other.ownsFavorites && home.ownsFavorites)
        #expect(other.favorites.isEmpty && home.holdsSomething)
        folder("Other's", in: other.favorites)
        let work = spaces.profiles.add()
        let before = other.favorites
        spaces.setProfile(work.profile.id, for: other)
        #expect(other.favorites === before, "its own Favorites stay through a change of profile")
        #expect(spaces.saved()[1].favorites.favorites.count == 1)
        #expect(spaces.profiles.saved(favorites: false).allSatisfy { $0.favorites.favorites.isEmpty })
        spaces.remove(other, movingTo: home)
        #expect(home.favorites.favorites.count == 2, "a deleted Space's Favorites go to where its tabs go")
        // Read back: each Space its own list.
        let saved = spaces.saved()
        let again = self.spaces(SpacesSession.Ownership(favoritesBySpace: true))
        again.restore(saved + [SavedSpace(space: Space(name: "Empty"))], reopening: true)
        #expect(again.spaces[0].favorites.favorites.count == 2 && again.spaces[1].favorites.isEmpty)
        #expect(again.spaces[1].favorites !== again.spaces[0].favorites)
    }

    @Test func `by profile: the Spaces of a profile share one list, as before`() {
        let spaces = spaces(SpacesSession.Ownership())
        let second = spaces.add(from: spaces.spaces[0])
        #expect(second.favorites === spaces.spaces[0].favorites && !second.ownsFavorites)
    }

    @Test func `one grid for the app: every profile shows the first's, saved once, never closed with a profile`() {
        let spaces = spaces(SpacesSession.Ownership(pinnedByApp: true))
        let work = spaces.profiles.add()
        #expect(work.pinned === spaces.profiles.first.pinned)
        folder("Pinned", in: work.pinned)
        let saved = spaces.profiles.saved()
        #expect(saved[0].pinned.favorites.count == 1 && saved[1].pinned.favorites.isEmpty)
        spaces.remove(profile: work)
        #expect(spaces.profiles.first.pinned.favorites.count == 1, "the shared grid stays")
        let own = self.spaces(SpacesSession.Ownership())
        #expect(own.profiles.add().pinned !== own.profiles.first.pinned)
    }
}
