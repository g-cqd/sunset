import Foundation
import SunsetPane
import Testing

@testable import SunsetShell

/// The Spaces of the app (roadmap 0021 steps S-b and S-c; the owner's answers of 2026-11-17): one order for every window;
/// a window shows one and changes to another; a Space left by changing keeps running; a tab moves to another Space
/// running, and the window follows it.
@MainActor
@Suite("The Spaces of the app")
struct SpacesModelTests {
    private func bar(_ query: String) -> CommandBar {
        var bar = CommandBar(purpose: .search)
        bar.query = query
        return bar
    }

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
    func `there is one Space, unnamed; the second names the first Home and is Space 2, with the profile's Favorites`()
        throws
    {
        let spaces = spaces()
        #expect(spaces.spaces.count == 1 && spaces.spaces[0].space.name.isEmpty && spaces.spaces[0].keepsTabs)
        let home = spaces.spaces[0]
        var folder: Favorites.NodeID?
        home.favorites.edit { folder = $0.addFolder(named: "Servers") }
        let second = spaces.add(from: home)
        #expect(spaces.spaces.map(\.space.name) == ["Home", "Space 2"])
        #expect(home.space.icon == .symbol("house") && second.space.icon == .symbol("2.circle"))
        // The Favorites are the profile's (ADR-0055): the same in both, not a copy.
        #expect(second.favorites === home.favorites && second.keepsTabs)
        let original = try #require(folder)
        #expect(second.favorites.favorites.count == 1 && second.favorites.favorites.node(original) != nil)
        #expect(second.tabs.isEmpty)
        // A name that is taken is not given twice; a Space that was named keeps its name.
        spaces.rename(home, to: "Space 3")
        #expect(spaces.add(from: second).space.name == "Space 4" && home.space.name == "Space 3")
        spaces.rename(second, to: "  ")
        #expect(second.space.name == "Space 2", "a Space is not left without a name")
    }

    @Test func `a window changes Space: it lists the other's tabs, and comes back to what it had selected`() throws {
        let (spaces, made) = (spaces(), MadeContents())
        let window = window(on: spaces, made: made)
        window.newTab()
        window.newTab()
        let first = try #require(window.workspace.items.first?.id)
        window.select(item: first)
        let work = spaces.add(from: spaces.spaces[0])
        window.show(space: work, in: spaces)
        #expect(window.space === work && window.workspace.isEmpty && window.shownItem == nil)
        #expect(made.all.allSatisfy { !$0.stopped && !$0.visible }, "left by changing: it runs on, shown nowhere")
        #expect(!spaces.spaces[0].isStopped && spaces.spaces[0].contents.count == 2)
        window.newTab()
        window.show(space: spaces.spaces[0], in: spaces)
        #expect(window.workspace.selectedID == first && made.all[0].visible && window.showsLive)
        window.show(space: work, in: spaces)
        #expect(window.workspace.count == 1 && window.workspace.selectedID != nil && made.all[2].visible)
    }

    @Test func `next and previous go round the Spaces in their order; the nth is the nth`() {
        let (spaces, made) = (spaces(), MadeContents())
        let window = window(on: spaces, made: made)
        let second = spaces.add(from: spaces.spaces[0])
        let third = spaces.add(from: spaces.spaces[0])
        window.stepSpace(by: 1)
        #expect(window.space === second)
        window.stepSpace(by: 1)
        window.stepSpace(by: 1)
        #expect(window.space === spaces.spaces[0], "round")
        window.stepSpace(by: -1)
        #expect(window.space === third)
        window.showSpace(number: 2)
        #expect(window.space === second)
        window.showSpace(number: 9)
        #expect(window.space === second, "there is no ninth")
    }

    @Test func `a tab moves to another Space running, and the window follows it there`() throws {
        let (spaces, made) = (spaces(), MadeContents())
        let window = window(on: spaces, made: made)
        window.newTab()
        window.newTab()
        let moving = try #require(window.workspace.selectedID)
        let work = spaces.add(from: spaces.spaces[0])
        window.move(rows: [.tab(moving)], to: work)
        #expect(window.space === work && window.workspace.items.map(\.id) == [moving])
        #expect(window.workspace.selectedID == moving && window.showsLive)
        #expect(!made.all[1].stopped && made.all[1].visible && !made.all[0].visible)
        #expect(spaces.spaces[0].tabs.count == 1 && spaces.spaces[0].contents.count == 1)
        // What ends by itself is closed in the Space it is in now.
        made.all[1].onExit()
        #expect(work.tabs.isEmpty && spaces.spaces[0].tabs.count == 1)
    }

    @Test
    func `a Space is deleted: what it held closes, or goes to another Space running; its windows go to the neighbour`()
        throws
    {
        let (spaces, made) = (spaces(), MadeContents())
        let window = window(on: spaces, made: made)
        let home = spaces.spaces[0]
        let work = spaces.add(from: home)
        let play = spaces.add(from: home)
        window.show(space: work, in: spaces)
        window.newTab()
        work.favorites.edit { $0.addFolder(named: "Kept") }
        #expect(work.holdsSomething && !play.holdsSomething, "its tab; the Favorites are the profile's")
        spaces.remove(work, movingTo: home)
        #expect(spaces.spaces.count == 2 && window.space === home)
        #expect(home.tabs.count == 1 && !made.all[0].stopped && home.favorites.favorites.count == 1)
        window.show(space: play, in: spaces)
        window.newTab()
        spaces.remove(play, movingTo: nil)
        #expect(made.all[1].stopped && spaces.spaces.count == 1 && window.space === home)
        spaces.remove(home, movingTo: nil)
        #expect(spaces.spaces.count == 1, "the last Space stays")
    }

    @Test func `the last window of the app closes: every Space stops and stays, the ones left by changing too`() throws
    {
        let (spaces, made) = (spaces(), MadeContents())
        let window = window(on: spaces, made: made)
        window.newTab()
        let work = spaces.add(from: spaces.spaces[0])
        window.show(space: work, in: spaces)
        window.newTab()
        window.windowClosed()
        #expect(made.all.allSatisfy(\.stopped) && spaces.spaces.allSatisfy(\.isStopped))
        #expect(spaces.spaces.map(\.tabs.count) == [1, 1])
    }

    @Test func `the Spaces are saved in their order, and come back with a window on the one it showed`() throws {
        let (spaces, made) = (spaces(), MadeContents())
        let window = window(on: spaces, made: made)
        window.newTab(.terminal(directory: "/home"))
        let work = spaces.add(from: spaces.spaces[0])
        window.show(space: work, in: spaces)
        window.newTab(.terminal(directory: "/work"))
        let saved = spaces.saved()
        #expect(saved.map(\.space.name) == ["Home", "Space 2"] && saved.map(\.tabs.count) == [1, 1])
        let view = window.savedView()
        #expect(view.space == work.space.id)
        let (again, remade) = (self.spaces(), MadeContents())
        again.restore(saved, reopening: true)
        #expect(again.spaces.map(\.space.name) == ["Home", "Space 2"] && again.spaces[1].space.id == work.space.id)
        let back = TabsModel()
        back.makeContent = { descriptor in
            let content = FakeContent(descriptor)
            remade.all.append(content)
            return content
        }
        back.show(view, in: again)
        #expect(back.space === again.spaces[1] && back.workspace.selectedID == view.selected)
        #expect(remade.all.map(\.descriptor.directory) == ["/work"], "the Space no window shows waits")
    }

    /// R4: the command bar finds a Space by its name, and a tab of another Space (going to it changes Space).
    @Test func `the bar finds the other Spaces by name, and their tabs; a tab of another Space is gone to there`()
        throws
    {
        let (spaces, made) = (spaces(), MadeContents())
        let window = window(on: spaces, made: made)
        window.newTab()
        made.all[0].detail = "/home/build"
        let work = spaces.add(from: spaces.spaces[0])
        spaces.rename(work, to: "Work")
        window.show(space: work)
        window.newTab()
        made.all[1].detail = "/srv/www"
        window.show(space: spaces.spaces[0])
        #expect(window.barSpaces(bar("wor")).map(\.space.name) == ["Work"], "not the one shown")
        #expect(window.barSpaces(bar("")).isEmpty)
        let found = window.barTabsElsewhere(bar("www"))
        #expect(found.count == 1 && found[0].space === work)
        #expect(window.barTabsElsewhere(bar("build")).isEmpty, "that one is here")
        window.show(found[0].item.id, in: found[0].space)
        #expect(window.space === work && window.workspace.selectedID == found[0].item.id && made.all[1].visible)
    }
}
