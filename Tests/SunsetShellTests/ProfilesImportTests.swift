import SunsetPane
import Testing

@testable import SunsetShellModel

/// Firefox's containers become Sunset profiles (roadmap 0111 D), once.
@MainActor @Suite("Containers as profiles")
struct ProfilesImportTests {
    @Test func `each name a profile, after the others; a name taken, or given twice, is not made again`() {
        let spaces = SpacesModel(makeFavorites: { FavoritesModel() })
        let profiles = spaces.profiles
        let before = profiles.profiles.count
        let made = profiles.adopt(named: ["Work", "Banking", " work ", "", "Banking"])
        #expect(made.map(\.profile.name) == ["Work", "Banking"])
        #expect(profiles.profiles.count == before + 2)
        let again = profiles.adopt(named: ["Work", "Shopping"])
        #expect(again.map(\.profile.name) == ["Shopping"])
        #expect(profiles.profiles.map(\.profile.name).suffix(3) == ["Work", "Banking", "Shopping"])
    }
}
