import Foundation
import Testing

@testable import SunsetHost

@Suite("Tab list") struct TabListTests {
    private func list(_ titles: String...) -> TabList {
        var list = TabList()
        for title in titles { list.add(title: title) }
        return list
    }

    @Test func `an empty list has no selection, and the first tab added is selected`() {
        var tabs = TabList()
        #expect(tabs.isEmpty && tabs.selectedID == nil && tabs.selectedIndex == nil)
        let first = tabs.add(title: "a")
        #expect(tabs.selectedID == first && tabs.count == 1)
    }

    @Test func `a new tab goes after the selected one and becomes selected`() {
        var tabs = list("a", "b", "c")
        tabs.select(index: 0)
        let new = tabs.add(title: "x")
        #expect(tabs.tabs.map(\.title) == ["a", "x", "b", "c"])
        #expect(tabs.selectedID == new)
    }

    @Test func `a new tab can go at the end instead`() {
        var tabs = list("a", "b", "c")
        tabs.select(index: 0)
        tabs.add(title: "x", after: .end)
        #expect(tabs.tabs.map(\.title) == ["a", "b", "c", "x"])
    }

    @Test func `closing the selected tab selects its right neighbour, or the left one at the end`() {
        var tabs = list("a", "b", "c")
        tabs.select(index: 1)
        tabs.close(tabs.tabs[1].id)
        #expect(tabs.tabs.map(\.title) == ["a", "c"] && tabs.selectedIndex == 1)
        tabs.close(tabs.tabs[1].id)
        #expect(tabs.tabs.map(\.title) == ["a"] && tabs.selectedIndex == 0)
        tabs.close(tabs.tabs[0].id)
        #expect(tabs.isEmpty && tabs.selectedID == nil)
    }

    @Test func `closing a tab that is not selected keeps the selection on the same tab`() {
        var tabs = list("a", "b", "c")
        tabs.select(index: 2)
        let selected = tabs.selectedID
        tabs.close(tabs.tabs[0].id)
        #expect(tabs.selectedID == selected && tabs.selectedIndex == 1)
    }

    @Test func `next and previous wrap around`() {
        var tabs = list("a", "b", "c")
        tabs.select(index: 2)
        tabs.selectNext()
        #expect(tabs.selectedIndex == 0)
        tabs.selectPrevious()
        #expect(tabs.selectedIndex == 2)
        var one = list("only")
        one.selectNext()
        #expect(one.selectedIndex == 0)
        var none = TabList()
        none.selectNext()
        #expect(none.selectedID == nil)
    }

    @Test func `a tab moves to a place, the selection stays on the same tab, and a place outside is brought inside`() {
        var tabs = list("a", "b", "c", "d")
        let selected = tabs.tabs[1].id
        tabs.select(id: selected)
        tabs.move(tabs.tabs[3].id, to: 0)
        #expect(tabs.tabs.map(\.title) == ["d", "a", "b", "c"] && tabs.selectedID == selected)
        tabs.move(tabs.tabs[0].id, to: 99)
        #expect(tabs.tabs.map(\.title) == ["a", "b", "c", "d"])
        tabs.move(tabs.tabs[0].id, to: -5)
        #expect(tabs.tabs.map(\.title) == ["a", "b", "c", "d"])
    }

    @Test func `selecting something that is not there changes nothing`() {
        var tabs = list("a", "b")
        tabs.select(index: 1)
        tabs.select(index: 9)
        tabs.select(index: -1)
        tabs.select(id: TabList.ID())
        #expect(tabs.selectedIndex == 1)
        tabs.close(TabList.ID())
        #expect(tabs.count == 2)
    }

    @Test func `a tab's title, directory and progress are set by id and ignored for an id that is gone`() {
        var tabs = list("a", "b")
        let id = tabs.tabs[1].id
        tabs.update(id) {
            $0.title = "vim"
            $0.directory = "/tmp"
            $0.progress = 0.5
        }
        #expect(tabs.tabs[1].title == "vim" && tabs.tabs[1].directory == "/tmp" && tabs.tabs[1].progress == 0.5)
        tabs.close(id)
        tabs.update(id) { $0.title = "nope" }
        #expect(tabs.tabs.map(\.title) == ["a"])
    }

    @Test func `closing all but one keeps that one selected`() {
        var tabs = list("a", "b", "c")
        let keep = tabs.tabs[1].id
        tabs.closeOthers(than: keep)
        #expect(tabs.tabs.map(\.id) == [keep] && tabs.selectedID == keep)
    }
}
