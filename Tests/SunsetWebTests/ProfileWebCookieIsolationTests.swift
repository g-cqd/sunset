import AemiTestKit
import Foundation
import SunsetPane
import SunsetShell
import SunsetShellModel
import SunsetTestSupport
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// End-to-end WebKit cookie/session isolation regression tests:
/// proves with a real local HTTP server and real `WKWebsiteDataStore` instances that two profiles never share cookies,
/// and that moving a live `WebContent` tab across Spaces (`move(rows:to:)`, cross-window drag, Space profile change)
/// reloads into the destination profile's store so the source profile's account session is never visible.
@MainActor
@Suite("WebKit cookie isolation across Spaces and profiles", .serialized, .timeLimit(.minutes(2)))
struct ProfileWebCookieIsolationTests {
    private func makeWindow(on space: SpaceModel, in spaces: SpacesModel) -> TabsModel {
        let tabs = TabsModel()
        tabs.show(space: space, in: spaces)
        tabs.makeContent = { [weak tabs] descriptor in
            var settings = WebSettings(applicationName: "Version/26.0 Safari/605.1.15")
            settings.profile = tabs?.space.space.profile
            return WebContent(descriptor: descriptor ?? PaneDescriptor(kind: WebContent.kind), settings: settings)
        }
        return tabs
    }

    private func loadCookie(_ page: WebContent, path: String) async throws -> String {
        page.setState(focused: true, visible: true)
        let view = try #require(page.webView)
        try await waitUntil(timeout: .seconds(15), label: "page loaded \(path)") {
            !view.isLoading && view.url?.path == path
        }
        return (try await view.evaluateJavaScript("document.cookie") as? String) ?? ""
    }

    private func makeTwoProfileSpaces(
        profileA: UUID,
        profileB: UUID
    ) -> (spaces: SpacesModel, spaceA: SpaceModel, spaceB: SpaceModel) {
        let spaces = SpacesModel(
            ownership: SpacesSession.Ownership(favoritesBySpace: true),
            makeFavorites: { FavoritesModel() }
        )
        let spaceA = spaces.spaces[0]
        spaceA.setProfile(profileA)
        var draftB = spaces.newDraft()
        draftB.name = "Work"
        draftB.profile = profileB
        let spaceB = spaces.add(from: spaceA, as: draftB)
        return (spaces, spaceA, spaceB)
    }

    private func signInServer(cookie: String) throws -> (server: EchoServer, login: URL, whoami: URL) {
        let server = try EchoServer(pages: [
            "/login": "<script>document.cookie='\(cookie); path=/';</script><p>signed in</p>",
            "/whoami": "<p>whoami</p>"
        ])
        let login = try #require(URL(string: "http://127.0.0.1:\(server.port)/login"))
        let whoami = try #require(URL(string: "http://127.0.0.1:\(server.port)/whoami"))
        return (server, login, whoami)
    }

    @Test(.macOS27) func `moving a logged-in web tab from Personal Space to Work Space isolates its cookie store`()
        async throws
    {
        let (profileA, profileB) = (UUID(), UUID())
        let (spaces, spaceA, spaceB) = makeTwoProfileSpaces(profileA: profileA, profileB: profileB)
        let env = try signInServer(cookie: "acct=personal_only")
        let window = makeWindow(on: spaceA, in: spaces)
        defer {
            spaceA.closeAll()
            spaceB.closeAll()
        }

        window.newTab(PaneDescriptor(kind: WebContent.kind, state: ["url": env.login.absoluteString]))
        let tabID = try #require(window.workspace.items.first?.id)
        let pane = try #require(window.workspace.items.first?.focused)
        let pageA = try #require(spaceA.contents[pane] as? WebContent)
        #expect(try await loadCookie(pageA, path: "/login").contains("acct=personal_only"))
        pageA.load(env.whoami)
        #expect(try await loadCookie(pageA, path: "/whoami").contains("acct=personal_only"))

        window.move(rows: [.tab(tabID)], to: spaceB)
        let pageB = try #require(spaceB.contents[pane] as? WebContent)
        #expect(pageB !== pageA && pageB.settings.profile == profileB)
        let cookieB = try await loadCookie(pageB, path: "/whoami")
        #expect(pageB.webView?.configuration.websiteDataStore.identifier == profileB)
        #expect(!cookieB.contains("acct=personal_only"))

        try? await WKWebsiteDataStore.remove(forIdentifier: profileA)
        try? await WKWebsiteDataStore.remove(forIdentifier: profileB)
    }

    @Test func `Space profile change isolates live WebKit cookies across both open tabs and Space-owned Favorites`()
        async throws
    {
        let (profileA, profileB) = (UUID(), UUID())
        let (spaces, space, _) = makeTwoProfileSpaces(profileA: profileA, profileB: profileB)
        let env = try signInServer(cookie: "acct=profile_a_secret")
        let window = makeWindow(on: space, in: spaces)
        defer {
            space.closeAll()
            space.favorites.closeAll()
        }

        window.newTab(PaneDescriptor(kind: WebContent.kind, state: ["url": env.login.absoluteString]))
        let tabPane = try #require(window.workspace.items.first?.focused)
        let tabPageA = try #require(space.contents[tabPane] as? WebContent)
        #expect(try await loadCookie(tabPageA, path: "/login").contains("acct=profile_a_secret"))
        tabPageA.load(env.whoami)
        #expect(try await loadCookie(tabPageA, path: "/whoami").contains("acct=profile_a_secret"))

        window.newTab(PaneDescriptor(kind: WebContent.kind, state: ["url": env.whoami.absoluteString]))
        let favTabID = try #require(window.workspace.items.last?.id)
        let favEntry = try #require(window.keep(item: favTabID, show: true))
        let favPaneA = try #require(space.favorites.favorites.entry(favEntry)?.open?.focused)
        let favPageA = try #require(space.favorites.contents[favPaneA] as? WebContent)
        #expect(try await loadCookie(favPageA, path: "/whoami").contains("acct=profile_a_secret"))

        window.edit(space: space)
        var draft = try #require(window.spaceDraft)
        draft.profile = profileB
        window.save(draft)

        window.select(item: try #require(space.tabs.items.first?.id))
        let tabPageB = try #require(space.contents[tabPane] as? WebContent)
        #expect(tabPageB !== tabPageA && tabPageB.settings.profile == profileB)
        #expect(!(try await loadCookie(tabPageB, path: "/whoami")).contains("acct=profile_a_secret"))
        #expect(tabPageB.webView?.configuration.websiteDataStore.identifier == profileB)

        window.select(entry: favEntry)
        let favPaneB = try #require(space.favorites.favorites.entry(favEntry)?.open?.focused)
        let favPageB = try #require(space.favorites.contents[favPaneB] as? WebContent)
        #expect(favPageB !== favPageA && favPageB.settings.profile == profileB)
        #expect(!(try await loadCookie(favPageB, path: "/whoami")).contains("acct=profile_a_secret"))
        #expect(favPageB.webView?.configuration.websiteDataStore.identifier == profileB)

        try? await WKWebsiteDataStore.remove(forIdentifier: profileA)
        try? await WKWebsiteDataStore.remove(forIdentifier: profileB)
    }

    @Test func `cross-window drag across profiles isolates live WebKit cookies even with per-Space Favorites`()
        async throws
    {
        let (profileA, profileB) = (UUID(), UUID())
        let (spaces, spaceA, spaceB) = makeTwoProfileSpaces(profileA: profileA, profileB: profileB)
        let env = try signInServer(cookie: "acct=drag_a_secret")
        let winA = makeWindow(on: spaceA, in: spaces)
        let winB = makeWindow(on: spaceB, in: spaces)
        defer {
            spaceA.closeAll()
            spaceB.closeAll()
        }

        winA.newTab(PaneDescriptor(kind: WebContent.kind, state: ["url": env.login.absoluteString]))
        let tabID = try #require(winA.workspace.items.first?.id)
        let pane = try #require(winA.workspace.items.first?.focused)
        let pageA = try #require(spaceA.contents[pane] as? WebContent)
        #expect(try await loadCookie(pageA, path: "/login").contains("acct=drag_a_secret"))
        pageA.load(env.whoami)
        #expect(try await loadCookie(pageA, path: "/whoami").contains("acct=drag_a_secret"))

        _ = winA.itemProvider(for: .item(tabID))
        #expect(winB.dropDragged(in: .today(at: 0)))
        winB.select(item: tabID)
        let pageB = try #require(spaceB.contents[pane] as? WebContent)
        #expect(pageB !== pageA && pageB.settings.profile == profileB)
        #expect(!(try await loadCookie(pageB, path: "/whoami")).contains("acct=drag_a_secret"))
        #expect(pageB.webView?.configuration.websiteDataStore.identifier == profileB)

        try? await WKWebsiteDataStore.remove(forIdentifier: profileA)
        try? await WKWebsiteDataStore.remove(forIdentifier: profileB)
    }

    @Test func `ExtensionWindow tracks profile dynamically and ExtensionHost binds its profile store`() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "ext-iso-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let (profileA, profileB) = (UUID(), UUID())
        var active: UUID?
        let extWindow = ExtensionWindow(profile: { active }, isPrivate: false, pages: { [] }, shown: { nil })
        #expect(extWindow.profile == nil)
        active = profileA
        #expect(extWindow.profile == profileA)

        let hostA = ExtensionHost(root: root, profile: profileA)
        let hostB = ExtensionHost(root: root, profile: profileB)
        #expect(hostA.controller.configuration.defaultWebsiteDataStore === VariantStore.store(for: profileA))
        #expect(hostB.controller.configuration.defaultWebsiteDataStore === VariantStore.store(for: profileB))
        #expect(
            hostA.controller.configuration.defaultWebsiteDataStore
                !== hostB.controller.configuration.defaultWebsiteDataStore
        )

        try? await WKWebsiteDataStore.remove(forIdentifier: profileA)
        try? await WKWebsiteDataStore.remove(forIdentifier: profileB)
    }
}
