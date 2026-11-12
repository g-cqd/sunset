import AppKit
import WebKit

/// The page's view: WebKit's, with the link menu R1 decided (Split Right, Split Down, New Tab, New Window, Copy Link) in place of WebKit's "Open Link in New
/// Window". Each new item asks WebKit to open the link as its own item would, and says where the page it makes goes (`pendingPlacement`).
final class SunsetWebView: WKWebView {
    /// Where the next page this view's menu asks for goes; read and cleared when WebKit asks for it.
    var pendingPlacement: WebPlacement?
    /// The link menu offers a private tab (not in a page that is private already).
    var offersPrivateTab = true
    /// It took the keyboard (a click in the page): its pane is the focused one.
    var onFocus: () -> Void = {}

    override func becomeFirstResponder() -> Bool {
        let took = super.becomeFirstResponder()
        if took { onFocus() }
        return took
    }

    override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
        super.willOpenMenu(menu, with: event)
        guard
            let index = menu.items.firstIndex(where: {
                $0.identifier?.rawValue == "WKMenuItemIdentifierOpenLinkInNewWindow"
            }),
            let action = menu.items[index].action
        else { return }
        let original = menu.items[index]
        menu.removeItem(at: index)
        var choices: [(String, WebPlacement)] = [
            ("Open Link in Split Right", .splitRight), ("Open Link in Split Down", .splitDown),
            ("Open Link in New Tab", .tabAfter), ("Open Link in New Window", .window)
        ]
        if offersPrivateTab { choices.append(("Open Link in Private Tab", .privateTab)) }
        // Each is WebKit's own item, retitled: WebKit opens the link as for its item, and asks for the new page, which goes where this one said.
        for (offset, choice) in choices.enumerated() {
            guard let item = original.copy() as? NSMenuItem else { continue }
            item.title = choice.0
            item.identifier = NSUserInterfaceItemIdentifier("sunset.openLink.\(offset)")
            item.action = action
            item.target = original.target
            item.representedObject = original.representedObject
            menu.insertItem(item, at: index + offset)
            placements[ObjectIdentifier(item)] = choice.1
        }
    }

    /// The placement of each of this menu's items, read when WebKit runs one of them.
    private var placements: [ObjectIdentifier: WebPlacement] = [:]

    override func didCloseMenu(_ menu: NSMenu, with event: NSEvent?) {
        super.didCloseMenu(menu, with: event)
        if let chosen = menu.highlightedItem, let placement = placements[ObjectIdentifier(chosen)] {
            pendingPlacement = placement
        }
        placements = [:]
    }
}
