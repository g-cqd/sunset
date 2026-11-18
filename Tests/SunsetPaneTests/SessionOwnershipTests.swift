import Foundation
import Testing

@testable import SunsetPane

/// Whose the Favorites and the Pinned grid are, as the session reads them (roadmap 0044): a file written one way is read
/// the other without losing what was kept.
@Suite("Whose the Favorites and the grid are, in the session")
struct SessionOwnershipTests {
    private func kept(_ name: String) -> SavedFavorites {
        var favorites = Favorites()
        _ = favorites.addFolder(named: name)
        return SavedFavorites(favorites: favorites)
    }

    private func names(_ saved: SavedFavorites) -> [String] {
        saved.favorites.nodes.compactMap { if case .folder(let folder) = $0 { folder.name } else { nil } }
    }

    @Test func `favorites by Space: a profile's list goes to its first Space, together with what that Space had`() {
        let work = Profile(name: "Work")
        var home = SavedSpace(space: Space(name: "Home"))
        home.favorites = kept("Home's")
        var office = Space(name: "Office")
        office.profile = work.id
        let profiles = [
            SavedProfile(profile: .first, favorites: kept("First's")),
            SavedProfile(profile: work, favorites: kept("Work's"))
        ]
        let session = SpacesSession(
            spaces: [home, SavedSpace(space: office), SavedSpace(space: Space(name: "Other"))],
            views: [],
            profiles: profiles,
            ownership: SpacesSession.Ownership(favoritesBySpace: true)
        )
        #expect(names(session.spaces[0].favorites) == ["First's", "Home's"])
        #expect(names(session.spaces[1].favorites) == ["Work's"])
        #expect(session.spaces[2].favorites.favorites.isEmpty)
        #expect(session.profiles.allSatisfy { $0.favorites.favorites.isEmpty }, "the profiles keep none")
        // Read back the other way, the Spaces' lists go to their profiles again (ADR-0055).
        let back = SpacesSession(spaces: session.spaces, views: [], profiles: session.profiles)
        #expect(names(back.profiles[0].favorites) == ["First's", "Home's"])
        #expect(back.spaces.allSatisfy { $0.favorites.favorites.isEmpty })
    }

    @Test func `one grid for the app: the other profiles' grids join the first's, which comes first`() throws {
        let work = Profile(name: "Work")
        let profiles = [
            SavedProfile(profile: .first, pinned: kept("First's")),
            SavedProfile(profile: work, pinned: kept("Work's"))
        ]
        let ownership = SpacesSession.Ownership(pinnedByApp: true)
        let session = SpacesSession(spaces: [], views: [], profiles: profiles, ownership: ownership)
        #expect(names(session.pinned) == ["First's", "Work's"])
        #expect(session.profiles[1].pinned.favorites.isEmpty && session.profiles[1].profile == work)
        let read = try #require(SpacesSession(data: try session.encoded(), ownership: ownership))
        #expect(read == session)
        let plain = SpacesSession(spaces: [], views: [], profiles: profiles)
        #expect(names(plain.profiles[1].pinned) == ["Work's"], "by profile, each keeps its own")
    }
}
