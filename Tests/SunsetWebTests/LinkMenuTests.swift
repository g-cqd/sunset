import AemiTestKit
import AppKit
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// "open in split and other open options on link in web tabs don't work", and keeping link options compact:
/// top-level "Open Link in New Tab" plus an "Open Link In" submenu (Split Right, Split Down, New Window, Private Tab),
/// while filling in missing page-level actions (Back, Forward, Copy Page Address, Print Page…) and collapsing stray separators.
@MainActor @Suite("A page's link and context menus")
struct LinkMenuTests {
    final class WebKitItem: NSObject {
        var hits: [NSMenuItem] = []
        @objc func open(_ sender: NSMenuItem) {
            hits.append(sender)
        }
    }

    @Test func `Open Link in New Tab is top-level and the remaining placements live in Open Link In submenu`() throws {
        let view = SunsetWebView(frame: .zero, configuration: WKWebViewConfiguration())
        let webKit = WebKitItem()
        let original = NSMenuItem(
            title: "Open Link in New Window",
            action: #selector(WebKitItem.open(_:)),
            keyEquivalent: ""
        )
        original.target = webKit
        original.representedObject = "the link"
        original.tag = 1
        let items = view.linkItems(replacing: original)
        #expect(items.map(\.title) == ["Open Link in New Tab", "Open Link In"])
        let newTab = items[0]
        #expect(newTab.tag == 1)
        _ = view.perform(newTab.action, with: newTab)
        #expect(view.pendingPlacement == .tabAfter)

        let submenu = try #require(items[1].submenu)
        #expect(submenu.items.map(\.title) == ["Split Right", "Split Down", "New Window", "Private Tab"])
        let down = submenu.items[1]
        _ = view.perform(down.action, with: down)
        #expect(view.pendingPlacement == .splitDown)
        #expect(webKit.hits.count == 2 && webKit.hits.allSatisfy { $0.representedObject as? String == "the link" })
        #expect(submenu.items.allSatisfy { $0.tag == 1 }, "each submenu item keeps WebKit's tag")

        view.offersPrivateTab = false
        let privateItems = view.linkItems(replacing: original)
        #expect(privateItems[1].submenu?.items.map(\.title) == ["Split Right", "Split Down", "New Window"])
    }

    @Test
    func `page background menu adds Back, Forward, Copy Page Address and Print Page, collapsing stray separators`()
        throws
    {
        let view = SunsetWebView(frame: .zero, configuration: WKWebViewConfiguration())
        var navigatedBack = false
        var copied = false
        view.pageNavState = { (canGoBack: true, canGoForward: false, hasURL: true) }
        view.onNavigateBack = { navigatedBack = true }
        view.onCopyPageAddress = { copied = true }

        let menu = NSMenu()
        let reload = NSMenuItem(title: "Reload", action: nil, keyEquivalent: "")
        reload.identifier = NSUserInterfaceItemIdentifier("WKMenuItemIdentifierReload")
        menu.addItem(reload)
        menu.addItem(.separator())
        menu.addItem(.separator())
        let inspect = NSMenuItem(title: "Inspect Element", action: nil, keyEquivalent: "")
        inspect.identifier = NSUserInterfaceItemIdentifier("WKMenuItemIdentifierInspectElement")
        menu.addItem(inspect)
        menu.addItem(.separator())

        view.addPageItems(to: menu)
        view.collapseSeparators(in: menu)
        #expect(
            menu.items.map { $0.isSeparatorItem ? "---" : $0.title } == [
                "Back", "Reload", "---", "Copy Page Address", "Print Page\u{2026}", "---", "Inspect Element"
            ]
        )
        _ = menu.items[0].target?.perform(menu.items[0].action, with: menu.items[0])
        _ = menu.items[3].target?.perform(menu.items[3].action, with: menu.items[3])
        #expect(navigatedBack && copied)
    }

    @Test func `WebKit's image and video items say they open a tab, and that they were chosen; others are left`() throws
    {
        let view = SunsetWebView(frame: .zero, configuration: WKWebViewConfiguration())
        let webKit = WebKitItem()
        let menu = NSMenu()
        for (identifier, title) in [
            ("WKMenuItemIdentifierOpenImageInNewWindow", "Open Image in New Window"),
            ("WKMenuItemIdentifierOpenMediaInNewWindow", "Open Video in New Window"),
            ("WKMenuItemIdentifierDownloadImage", "Download Image")
        ] {
            let item = NSMenuItem(title: title, action: #selector(WebKitItem.open(_:)), keyEquivalent: "")
            item.target = webKit
            item.identifier = NSUserInterfaceItemIdentifier(identifier)
            menu.addItem(item)
        }
        view.retitleOpenedItems(in: menu)
        #expect(menu.items.map(\.title) == ["Open Image in New Tab", "Open Video in New Tab", "Download Image"])
        let image = menu.items[0]
        _ = view.perform(image.action, with: image)
        #expect(view.pendingPlacement == .opened, "chosen: WebKit's request is let through")
        #expect(webKit.hits.count == 1, "then WebKit's own action")
        #expect(menu.items[2].target === webKit, "Download Image left as it is")
    }

    @Test func `a chosen item's page skips the pop-up rule`() {
        #expect(WebCoordinator.skipsPopupRule(chosen: .opened))
        #expect(WebCoordinator.skipsPopupRule(chosen: .splitRight))
        #expect(!WebCoordinator.skipsPopupRule(chosen: nil))
    }

    @Test func `WebKit's Search the web searches with Sunset's engine in a tab`() async throws {
        var settings = WebSettings(applicationName: "x")
        settings.engine = SearchEngine.builtIn.first { $0.name == "DuckDuckGo" } ?? settings.engine
        let page = WebContent(url: nil, settings: settings)
        var opened: [(WebContent, WebPlacement)] = []
        page.onOpen = { opened.append(($0, $1)) }
        page.setState(focused: true, visible: true)
        defer { page.stop() }
        let menu = NSMenu()
        let item = NSMenuItem(title: "Search with Google", action: #selector(WebKitItem.open(_:)), keyEquivalent: "")
        item.identifier = NSUserInterfaceItemIdentifier("WKMenuItemIdentifierSearchWeb")
        menu.addItem(item)
        let view = try #require(page.webView as? SunsetWebView)
        view.searchWords = { "a few words" }
        view.retitleSearchItem(in: menu)
        #expect(item.title == "Search with \(settings.engine.name)")
        _ = view.perform(item.action, with: item)
        try await waitUntil(timeout: .seconds(5), label: "the search opened") { opened.count == 1 }
        #expect(opened[0].1 == .opened)
        #expect(opened[0].0.url == settings.engine.searchURL("a few words"))
    }
}
