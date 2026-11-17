import Foundation
import SunsetPane
import Testing

@testable import SunsetShell

/// While a tab is dragged the places that would take it show (the owner, 2026-11-17: "when dragging, we might want that
/// the target area show so that we know where to drop tabs"). A drag is known from its start until it is dropped, or
/// until the mouse button is let go anywhere else.
@MainActor
@Suite("What shows while a tab is dragged")
struct TabsDragTargetsTests {
    private func window(_ made: MadeContents) -> TabsModel {
        let tabs = TabsModel()
        tabs.makeContent = { descriptor in
            let content = FakeContent(descriptor ?? .terminal(directory: nil))
            made.all.append(content)
            return content
        }
        tabs.pinned = FavoritesModel()
        return tabs
    }

    @Test func `a drag is under way from its start until it is dropped`() throws {
        let tabs = window(MadeContents())
        tabs.newTab()
        tabs.newTab()
        let first = try #require(tabs.workspace.items.first?.id)
        #expect(tabs.dragTargets == nil)
        _ = tabs.itemProvider(for: .item(first))
        let targets = try #require(tabs.dragTargets)
        #expect(targets.pinned && targets.favorites && targets.panes)
        #expect(tabs.pinDragged() && tabs.dragTargets == nil)
    }

    @Test func `a drag let go where nothing takes it ends when the mouse button is up`() async throws {
        let tabs = window(MadeContents())
        let button = Button()
        tabs.mouseIsDown = { button.down }
        tabs.newTab()
        let first = try #require(tabs.workspace.items.first?.id)
        _ = tabs.itemProvider(for: .item(first))
        try await Task.sleep(for: .milliseconds(150))
        #expect(tabs.dragTargets != nil, "still held")
        button.down = false
        for _ in 0 ..< 40 where tabs.dragTargets != nil { try await Task.sleep(for: .milliseconds(25)) }
        #expect(tabs.dragTargets == nil && tabs.dragged == nil)
    }

    /// A pane carries its tab to the grid and the Favorites (roadmap 0035 A; it went to neither before).
    @Test func `what shows is what would take it: a pane goes as its tab, a full grid takes nothing`() throws {
        let tabs = window(MadeContents())
        tabs.newTab()
        let pane = try #require(tabs.workspace.selectedPane)
        _ = tabs.itemProvider(for: .pane(pane))
        let ofPane = try #require(tabs.dragTargets)
        #expect(ofPane.pinned && ofPane.favorites)
        tabs.endDrag()
        for _ in 0 ..< TabsModel.pinnedLimit {
            tabs.newTab()
            let tab = try #require(tabs.workspace.selectedID)
            _ = tabs.pin(item: tab, show: false)
        }
        tabs.newTab()
        let tab = try #require(tabs.workspace.selectedID)
        _ = tabs.itemProvider(for: .item(tab))
        let full = try #require(tabs.dragTargets)
        #expect(!full.pinned && full.favorites)
    }

    /// A mouse button, held or not.
    @MainActor final class Button {
        var down = true
    }
}
