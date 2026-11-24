import Foundation
import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The owner's note n146: with restoring on, all the tabs of the last session are listed again, and none is loaded until it is
/// shown. Every restored terminal used to start a shell at launch.
@MainActor @Suite("Restored tabs wait until they are shown")
struct RestoredTabsWaitTests {
    private func spaces() -> SpacesModel {
        SpacesModel(makeFavorites: { FavoritesModel() })
    }

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

    @Test func `only the tab shown is made; the others are listed, kept to start from, made when shown`() throws {
        let (first, ignored) = (spaces(), MadeContents())
        let before = window(on: first, made: ignored)
        for directory in ["/a", "/b", "/c"] { before.newTab(.terminal(directory: directory)) }
        before.select(index: 1)
        let saved = first.saved()
        let view = before.savedView()
        #expect(saved[0].tabs.count == 3)

        let (again, made) = (spaces(), MadeContents())
        again.restore(saved, reopening: true)
        let back = window(on: again, made: made)
        back.show(view, in: again)

        #expect(back.workspace.count == 3, "every tab of the last session is listed")
        #expect(made.all.map(\.descriptor.directory) == ["/b"], "only the one shown runs")
        let waiting = back.workspace.items.filter { $0.id != view.selected }
        #expect(waiting.count == 2 && waiting.allSatisfy { back.content($0.focused) == nil })
        #expect(
            waiting.compactMap { back.pendingDescriptor($0.focused)?.directory }.sorted() == ["/a", "/c"],
            "what each is started from, for its row and its preview"
        )
        // Saved again at once, nothing is lost.
        #expect(again.saved()[0].contents.values.compactMap(\.directory).sorted() == ["/a", "/b", "/c"])

        let target = try #require(waiting.first)
        back.select(item: target.id)
        #expect(back.content(target.focused) != nil, "shown, it is made from where it was")
        #expect(made.all.count == 2)
    }
}
