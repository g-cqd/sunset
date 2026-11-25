import Foundation
import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// Regression suite for profile isolation on Space deletion, Space profile edits, profile removal, and app-shared
/// Pinned grids / Space-owned Favorites.
@MainActor
@Suite("Profile isolation: Favorites, Pinned grids, and Space lifecycle", .serialized)
struct ProfileIsolationLifecycleTests {
    @Test func `deleting a Space into a neighbour of ANOTHER profile restarts moved tabs AND Space-owned Favorites`()
        throws
    {
        let rig = ProfileIsolationRig()
        let window = rig.window(on: rig.work)
        window.newTab(rig.page)
        window.newTab(rig.page)
        let favTab = window.workspace.items[1].id
        let favEntry = try #require(window.keep(item: favTab, show: false))
        let tabPane = window.workspace.items[0].focused
        let favPane = try #require(rig.work.favorites.favorites.entry(favEntry)?.open?.focused)
        let oldTabPage = try #require(rig.work.contents[tabPane] as? FakeContent)
        let oldFavPage = try #require(rig.work.favorites.contents[favPane] as? FakeContent)

        rig.spaces.remove(rig.work, movingTo: rig.personal)
        #expect(window.space === rig.personal)
        #expect(oldTabPage.stopped && oldFavPage.stopped)

        window.select(item: rig.personal.tabs.items[0].id)
        let newTabPage = try #require(rig.personal.contents[tabPane] as? FakeContent)
        #expect(rig.profile(of: newTabPage) == .some(nil))

        window.select(entry: favEntry)
        let newFavPane = try #require(rig.personal.favorites.favorites.entry(favEntry)?.open?.focused)
        let newFavPage = try #require(rig.personal.favorites.contents[newFavPane] as? FakeContent)
        #expect(rig.profile(of: newFavPage) == .some(nil))
    }

    @Test func `changing a Space's profile restarts both its open tabs AND its Space-owned open Favorites`() throws {
        let rig = ProfileIsolationRig()
        let window = rig.window(on: rig.personal)
        window.newTab(rig.page)
        window.newTab(rig.page)
        let favEntry = try #require(window.keep(item: window.workspace.items[1].id, show: false))
        let tabPane = window.workspace.items[0].focused
        let favPane = try #require(rig.personal.favorites.favorites.entry(favEntry)?.open?.focused)
        let oldTabPage = try #require(rig.personal.contents[tabPane] as? FakeContent)
        let oldFavPage = try #require(rig.personal.favorites.contents[favPane] as? FakeContent)

        window.edit(space: rig.personal)
        var draft = try #require(window.spaceDraft)
        draft.profile = rig.workProfile.profile.id
        window.save(draft)

        #expect(oldTabPage.stopped && oldFavPage.stopped)
        #expect(rig.personal.favorites.favorites.entry(favEntry)?.isOpen == false)

        window.select(item: rig.personal.tabs.items[0].id)
        #expect(rig.profile(of: rig.personal.contents[tabPane]) == .some(rig.workProfile.profile.id))

        window.select(entry: favEntry)
        let newFavPane = try #require(rig.personal.favorites.favorites.entry(favEntry)?.open?.focused)
        #expect(rig.profile(of: rig.personal.favorites.contents[newFavPane]) == .some(rig.workProfile.profile.id))
    }

    @Test func `removing a profile restarts Space-owned open Favorites in its Spaces as well as tabs`() throws {
        let rig = ProfileIsolationRig()
        let window = rig.window(on: rig.work)
        window.newTab(rig.page)
        let favEntry = try #require(window.keep(item: window.workspace.items[0].id, show: false))
        let favPane = try #require(rig.work.favorites.favorites.entry(favEntry)?.open?.focused)
        let oldFavPage = try #require(rig.work.favorites.contents[favPane] as? FakeContent)

        _ = rig.spaces.remove(profile: rig.workProfile)
        rig.work.restart(kind: "web", by: rig.work.currentViewer)
        #expect(oldFavPage.stopped)
    }

    @Test func `app-shared Pinned grid entry opened in Personal and shown in Work restarts under Work's profile`()
        throws
    {
        let rig = ProfileIsolationRig(ownership: SpacesSession.Ownership(favoritesBySpace: true, pinnedByApp: true))
        let window = rig.window(on: rig.personal)
        window.newTab(rig.page)
        let pinnedID = try #require(window.pin(item: window.workspace.items[0].id, show: true))
        let personalPane = try #require(window.pinned?.favorites.entry(pinnedID)?.open?.focused)
        let personalPage = try #require(window.pinned?.contents[personalPane] as? FakeContent)

        window.show(space: rig.work)
        window.select(entry: pinnedID)
        let workPane = try #require(window.pinned?.favorites.entry(pinnedID)?.open?.focused)
        let workPage = try #require(window.pinned?.contents[workPane] as? FakeContent)
        #expect(personalPage.stopped && workPage !== personalPage)
        #expect(rig.profile(of: workPage) == .some(rig.workProfile.profile.id))
    }

    @Test func `releasing a shared Pinned entry from Personal into Work restarts web pages under Work's profile`()
        throws
    {
        let rig = ProfileIsolationRig(ownership: SpacesSession.Ownership(favoritesBySpace: true, pinnedByApp: true))
        let window = rig.window(on: rig.personal)
        window.newTab(rig.page)
        let pinnedID = try #require(window.pin(item: window.workspace.items[0].id, show: true))
        let personalPane = try #require(window.pinned?.favorites.entry(pinnedID)?.open?.focused)
        let personalPage = try #require(window.pinned?.contents[personalPane] as? FakeContent)

        window.show(space: rig.work)
        let releasedTab = try #require(window.release(entry: pinnedID))
        let pane = try #require(rig.work.tabs.items.first { $0.id == releasedTab }?.focused)
        let releasedPage = try #require(rig.work.contents[pane] as? FakeContent)
        #expect(personalPage.stopped && releasedPage !== personalPage)
        #expect(rig.profile(of: releasedPage) == .some(rig.workProfile.profile.id))
    }

    @Test func `moving an app-shared Pinned entry to Favorites in Work unloads Personal's live page first`() throws {
        let rig = ProfileIsolationRig(ownership: SpacesSession.Ownership(favoritesBySpace: true, pinnedByApp: true))
        let window = rig.window(on: rig.personal)
        window.newTab(rig.page)
        let pinnedID = try #require(window.pin(item: window.workspace.items[0].id, show: true))
        let personalPane = try #require(window.pinned?.favorites.entry(pinnedID)?.open?.focused)
        let personalPage = try #require(window.pinned?.contents[personalPane] as? FakeContent)

        window.show(space: rig.work)
        #expect(window.favorite(pinned: pinnedID))
        #expect(personalPage.stopped && rig.work.favorites.favorites.entry(pinnedID)?.isOpen == false)

        window.select(entry: pinnedID)
        let workPane = try #require(rig.work.favorites.favorites.entry(pinnedID)?.open?.focused)
        let workPage = try #require(rig.work.favorites.contents[workPane] as? FakeContent)
        #expect(rig.profile(of: workPage) == .some(rig.workProfile.profile.id))
    }
}
