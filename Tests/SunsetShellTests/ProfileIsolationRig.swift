import Foundation
import SunsetPane

@testable import SunsetShell
@testable import SunsetShellModel

/// Shared harness for profile-isolation regression suites across Spaces, tabs, Favorites, and Pinned grids.
@MainActor
final class ProfileIsolationRig {
    let page = PaneDescriptor(kind: "web", state: ["url": "https://account.example/"])
    let terminal = PaneDescriptor.terminal(directory: "/tmp")
    let spaces: SpacesModel
    let personal: SpaceModel
    let work: SpaceModel
    let workProfile: ProfileModel
    private var profiles: [ObjectIdentifier: Profile.ID?] = [:]

    init(ownership: SpacesSession.Ownership = SpacesSession.Ownership(favoritesBySpace: true)) {
        spaces = SpacesModel(ownership: ownership, makeFavorites: { FavoritesModel() })
        personal = spaces.spaces[0]
        workProfile = spaces.profiles.add()
        spaces.profiles.rename(workProfile, to: "Work")
        var draft = spaces.newDraft()
        draft.name = "Work"
        draft.profile = workProfile.profile.id
        work = spaces.add(from: personal, as: draft)
    }

    func window(on space: SpaceModel) -> TabsModel {
        let tabs = TabsModel()
        tabs.show(space: space, in: spaces)
        tabs.makeContent = { [weak tabs, weak self] descriptor in
            let content = FakeContent(descriptor)
            self?.profiles[ObjectIdentifier(content)] = tabs?.space.space.profile
            return content
        }
        return tabs
    }

    func standaloneWindow() -> TabsModel {
        let tabs = TabsModel()
        tabs.makeContent = { [weak tabs, weak self] descriptor in
            let content = FakeContent(descriptor)
            self?.profiles[ObjectIdentifier(content)] = tabs?.space.space.profile
            return content
        }
        return tabs
    }

    func profile(of content: (any PaneContent)?) -> Profile.ID?? {
        content.map { profiles[ObjectIdentifier($0)] } ?? nil
    }
}
