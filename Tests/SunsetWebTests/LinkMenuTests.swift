import AppKit
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// The owner's note n51: "open in split and other open options on link in web tabs don't work". WebKit runs a menu item's
/// action, and asks for the new page, before the view hears that the menu closed (probed: `/tmp/linkmenu`), so a placement
/// read when it closes came too late and every link opened as a tab. Each item says where it goes as it is chosen.
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
    }

    /// Notes n64 and n65: WebKit's Open Image in New Window opens the picture in a tab, shown; its title says where.
    @Test func `WebKit's image and video items say they open a tab; the link's and others are left`() {
        let menu = NSMenu()
        for (identifier, title) in [
            ("WKMenuItemIdentifierOpenImageInNewWindow", "Open Image in New Window"),
            ("WKMenuItemIdentifierOpenMediaInNewWindow", "Open Video in New Window"),
            ("WKMenuItemIdentifierOpenLinkInNewWindow", "Open Link in New Window"),
            ("WKMenuItemIdentifierDownloadImage", "Download Image")
        ] {
            let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            item.identifier = NSUserInterfaceItemIdentifier(identifier)
            menu.addItem(item)
        }
        SunsetWebView.retitleOpenedItems(in: menu)
        #expect(
            menu.items.map(\.title) == [
                "Open Image in New Tab", "Open Video in New Tab", "Open Link in New Window", "Download Image"
            ]
        )
    }
}
