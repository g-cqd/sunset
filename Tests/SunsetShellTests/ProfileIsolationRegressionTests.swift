import Foundation
import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// Regression suite for tab movement & drag profile isolation across Spaces:
/// moving, dragging, joining, or dropping pending tabs across Spaces of different profiles must never leave a live web
/// page from one profile running in a Space of another profile.
@MainActor
@Suite("Profile isolation: moving and dragging tabs across Spaces", .serialized)
struct ProfileIsolationRegressionTests {
    @Test func `Move to Space across profiles restarts web pages under the target profile and keeps terminals running`()
        throws
    {
        let rig = ProfileIsolationRig()
        let window = rig.window(on: rig.personal)
        window.newTab(rig.page)
        window.newTab(rig.terminal)
        let pageTab = window.workspace.items[0].id
        let terminalTab = window.workspace.items[1].id
        let oldPage = try #require(rig.personal.contents[window.workspace.items[0].focused] as? FakeContent)
        let oldTerm = try #require(rig.personal.contents[window.workspace.items[1].focused] as? FakeContent)
        #expect(rig.profile(of: oldPage) == .some(nil))

        window.move(rows: [.tab(pageTab), .tab(terminalTab)], to: rig.work)
        #expect(window.space === rig.work)
        #expect(oldPage.stopped, "Personal profile web page must be stopped when moved to Work Space")
        #expect(!oldTerm.stopped, "terminal continues running across profiles")

        window.select(item: pageTab)
        let newPage = try #require(rig.work.contents[rig.work.tabs.items[0].focused] as? FakeContent)
        #expect(newPage !== oldPage && rig.profile(of: newPage) == .some(rig.workProfile.profile.id))
        #expect(newPage.descriptor.state["url"] == "https://account.example/")
    }

    @Test func `Move to Space within the SAME profile keeps web pages running without reload`() throws {
        let rig = ProfileIsolationRig()
        let personal2 = rig.spaces.add(from: rig.personal)
        let window = rig.window(on: rig.personal)
        window.newTab(rig.page)
        let pageTab = window.workspace.items[0].id
        let oldPage = try #require(rig.personal.contents[window.workspace.items[0].focused] as? FakeContent)

        window.move(rows: [.tab(pageTab)], to: personal2)
        #expect(!oldPage.stopped && personal2.contents[personal2.tabs.items[0].focused] === oldPage)
    }

    @Test func `Move to Space across profiles strips Reload As override from the source Space`() throws {
        let rig = ProfileIsolationRig()
        let reloaded = PaneDescriptor(
            kind: "web",
            state: ["url": "https://account.example/", "as": rig.workProfile.profile.id.uuidString]
        )
        let window = rig.window(on: rig.personal)
        window.newTab(reloaded)
        let tabID = window.workspace.items[0].id
        let pane = window.workspace.items[0].focused

        let thirdProfile = rig.spaces.profiles.add()
        var draft = rig.spaces.newDraft()
        draft.name = "Third"
        draft.profile = thirdProfile.profile.id
        let third = rig.spaces.add(from: rig.personal, as: draft)

        window.move(rows: [.tab(tabID)], to: third)
        let newPage = try #require(third.contents[pane] as? FakeContent)
        #expect(rig.profile(of: newPage) == .some(thirdProfile.profile.id))
        #expect(newPage.descriptor.state["as"] == nil)
    }

    @Test
    func `cross-window drag between Spaces of the SAME profile with per-Space Favorites does NOT reload web page`()
        throws
    {
        let rig = ProfileIsolationRig()
        let personal2 = rig.spaces.add(from: rig.personal)
        let win1 = rig.window(on: rig.personal)
        let win2 = rig.window(on: personal2)
        win1.newTab(rig.page)
        let tabID = win1.workspace.items[0].id
        let oldPage = try #require(rig.personal.contents[win1.workspace.items[0].focused] as? FakeContent)

        _ = win1.itemProvider(for: .item(tabID))
        #expect(win2.dropDragged(in: .today(at: 0)))
        #expect(!oldPage.stopped && personal2.contents[personal2.tabs.items[0].focused] === oldPage)
    }

    @Test
    func `cross-window drag between Spaces of DIFFERENT profiles restarts web page even with per-Space Favorites`()
        throws
    {
        let rig = ProfileIsolationRig()
        let win1 = rig.window(on: rig.personal)
        let win2 = rig.window(on: rig.work)
        win1.newTab(rig.page)
        let tabID = win1.workspace.items[0].id
        let oldPage = try #require(rig.personal.contents[win1.workspace.items[0].focused] as? FakeContent)

        _ = win1.itemProvider(for: .item(tabID))
        #expect(win2.dropDragged(in: .today(at: 0)))
        #expect(oldPage.stopped)
        win2.select(item: tabID)
        let newPage = try #require(rig.work.contents[win2.workspace.items[0].focused] as? FakeContent)
        #expect(newPage !== oldPage && rig.profile(of: newPage) == .some(rig.workProfile.profile.id))
    }

    @Test func `moving a split tab containing both web and terminal across profiles restarts only the web pane`() throws
    {
        let rig = ProfileIsolationRig()
        let window = rig.window(on: rig.personal)
        window.newTab(rig.page)
        window.newSplit(.right)
        let tabID = window.workspace.items[0].id
        let panes = window.workspace.items[0].panes
        let webPane = try #require(panes.first { rig.personal.contents[$0]?.descriptor.kind == "web" })
        let termPane = try #require(panes.first { $0 != webPane })
        let oldWeb = try #require(rig.personal.contents[webPane] as? FakeContent)
        let oldTerm = try #require(rig.personal.contents[termPane] as? FakeContent)

        window.move(rows: [.tab(tabID)], to: rig.work)
        #expect(oldWeb.stopped && !oldTerm.stopped)
        let newWeb = try #require(rig.work.contents[webPane] as? FakeContent)
        #expect(newWeb !== oldWeb && rig.profile(of: newWeb) == .some(rig.workProfile.profile.id))
        #expect(rig.work.contents[termPane] === oldTerm)
    }

    @Test func `private web tabs are NOT stopped or reloaded when moved across Spaces of different profiles`() throws {
        let rig = ProfileIsolationRig()
        let window = rig.window(on: rig.personal)
        window.newTab(PaneDescriptor(kind: "web", state: ["url": "https://priv.example/", "private": "1"]))
        let tabID = window.workspace.items[0].id
        let pane = window.workspace.items[0].focused
        let privPage = try #require(rig.personal.contents[pane] as? FakeContent)
        privPage.isPrivate = true

        window.move(rows: [.tab(tabID)], to: rig.work)
        #expect(!privPage.stopped && rig.work.contents[pane] === privPage)
    }

    @Test func `join across profiles restarts moved web tabs under the destination Space's profile`() throws {
        let rig = ProfileIsolationRig()
        let standalone = rig.standaloneWindow()
        standalone.newTab(rig.page)
        let pane = standalone.workspace.items[0].focused
        let oldPage = try #require(standalone.contents[pane] as? FakeContent)

        standalone.join(rig.work)
        #expect(oldPage.stopped)
        let newPage = try #require(rig.work.contents[pane] as? FakeContent)
        #expect(newPage !== oldPage && rig.profile(of: newPage) == .some(rig.workProfile.profile.id))
    }

    @Test func `dragging an unloaded pending web tab across profiles strips its stale Reload As profile`() throws {
        let rig = ProfileIsolationRig()
        let thirdProfile = rig.spaces.profiles.add()
        var ws = Workspace()
        let added = ws.add()
        rig.personal.restore(
            SavedSpace(
                space: rig.personal.space,
                favorites: SavedFavorites(),
                tabs: ws,
                contents: [
                    added.pane: PaneDescriptor(
                        kind: "web",
                        state: ["url": "https://pending.example/", "as": thirdProfile.profile.id.uuidString]
                    )
                ]
            ),
            reopening: true
        )
        let win1 = rig.window(on: rig.personal)
        let win2 = rig.window(on: rig.work)

        _ = win1.itemProvider(for: .item(added.item))
        #expect(win2.dropDragged(in: .today(at: 0)))
        win2.select(item: added.item)
        let revived = try #require(rig.work.contents[added.pane] as? FakeContent)
        #expect(rig.profile(of: revived) == .some(rig.workProfile.profile.id))
        #expect(revived.descriptor.state["as"] == nil)
    }
}
