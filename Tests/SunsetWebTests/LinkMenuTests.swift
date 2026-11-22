import AemiTestKit
import AppKit
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// "open in split and other open options on link in web tabs don't work". WebKit runs a menu item's action, and asks for
/// the new page, before the view hears that the menu closed (probed: `/tmp/linkmenu`), so a placement read when it closes
/// came too late and every link opened as a tab. Each item says where it goes as it is chosen.
@MainActor @Suite("A page's link menu")
struct LinkMenuTests {
    final class WebKitItem: NSObject {
        var hits: [NSMenuItem] = []
        @objc func open(_ sender: NSMenuItem) {
            hits.append(sender)
        }
    }

    @Test func `each item sets its placement, then runs WebKit's own action with its represented object`() throws {
        let view = SunsetWebView(frame: .zero, configuration: WKWebViewConfiguration())
        let webKit = WebKitItem()
        let original = NSMenuItem(
            title: "Open Link in New Window",
            action: #selector(WebKitItem.open(_:)),
            keyEquivalent: ""
        )
        original.target = webKit
        original.representedObject = "the link"
        // WebKit tells its actions apart by the item's tag (`forwardContextMenuAction:`; seen 2026-11-20: 1 for Open Link
        // in New Window): an item that sends it another tag runs another action, or none.
        original.tag = 1
        let items = view.linkItems(replacing: original)
        #expect(
            items.map(\.title) == [
                "Open Link in Split Right", "Open Link in Split Down", "Open Link in New Tab",
                "Open Link in New Window",
                "Open Link in Private Tab"
            ]
        )
        let down = items[1]
        let action = try #require(down.action)
        _ = view.perform(action, with: down)
        #expect(view.pendingPlacement == .splitDown)
        #expect(webKit.hits.count == 1 && webKit.hits.first?.representedObject as? String == "the link")
        #expect(items.allSatisfy { $0.tag == 1 }, "each item keeps WebKit's tag")
    }

    /// WebKit's Open Image in New Window opens the picture in a tab, shown; its title says where. WebKit marks the page it
    /// asks for as not opened by the person (probed 2026-11-20, `/tmp/n64probe/menu.swift`): the item says it was chosen, so
    /// that the pop-up rule does not stop it.
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

    /// A page WebKit asks for after a menu item was chosen is let through; one asked without is the pop-up rule's.
    @Test func `a chosen item's page skips the pop-up rule`() {
        #expect(WebCoordinator.skipsPopupRule(chosen: .opened))
        #expect(WebCoordinator.skipsPopupRule(chosen: .splitRight))
        #expect(!WebCoordinator.skipsPopupRule(chosen: nil))
    }

    /// Seen on screen 2026-11-20: the text menu's Search with Google opened Safari (WebKit gives the words to the system's
    /// default browser). In Sunset it searches with Sunset's engine, in a tab after the page, shown, titled with its name.
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
