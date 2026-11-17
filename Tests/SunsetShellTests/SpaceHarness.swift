import SunsetPane

@testable import SunsetShell

/// A Space and windows on it, for tests: fake contents, and what each window was told.
@MainActor final class SpaceHarness {
    let space: SpaceModel
    var made: [FakeContent] = []
    var emptied: [ObjectIdentifier] = []
    var wired: [(window: ObjectIdentifier, content: FakeContent)] = []

    init(keepsTabs: Bool = true, favorites: FavoritesModel = FavoritesModel()) {
        space = SpaceModel(favorites: favorites, keepsTabs: keepsTabs)
    }

    /// A window on the Space, with nothing selected.
    func window() -> TabsModel {
        let tabs = TabsModel(space: space)
        tabs.makeContent = { [weak self] descriptor in
            let content = FakeContent(descriptor)
            self?.made.append(content)
            return content
        }
        tabs.wireContent = { [weak self, weak tabs] content in
            guard let tabs, let fake = content as? FakeContent else { return }
            self?.wired.append((ObjectIdentifier(tabs), fake))
        }
        tabs.onEmpty = { [weak self, weak tabs] in
            if let tabs { self?.emptied.append(ObjectIdentifier(tabs)) }
        }
        return tabs
    }

    func content(_ pane: PaneID) -> FakeContent? { space.contents[pane] as? FakeContent }

    /// The content of the one pane of tab `index`.
    func content(tab index: Int) -> FakeContent? { content(space.tabs.items[index].focused) }
}
