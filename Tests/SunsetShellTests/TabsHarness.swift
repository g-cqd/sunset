import SunsetPane

@testable import SunsetShell

/// A tab model that makes `FakeContent`s, with what it made, the number of changes it reported and whether it said it was empty.
@MainActor final class TabsHarness {
    let tabs: TabsModel
    var made: [FakeContent] = []
    var changes = 0
    var emptied = false

    init(favorites: FavoritesModel = FavoritesModel()) {
        tabs = TabsModel(favorites: favorites)
        tabs.makeContent = { [weak self] descriptor in
            let content = FakeContent(descriptor)
            self?.made.append(content)
            return content
        }
        tabs.onChange = { [weak self] in self?.changes += 1 }
        tabs.onEmpty = { [weak self] in self?.emptied = true }
    }

    func content(_ pane: PaneID) -> FakeContent? { tabs.content(pane) as? FakeContent }
}
