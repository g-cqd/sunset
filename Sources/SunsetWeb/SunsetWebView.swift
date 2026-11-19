import AppKit
import SunsetShell
import WebKit

/// The page's view: WebKit's, with the link menu R1 decided (Split Right, Split Down, New Tab, New Window, Copy Link) in place of WebKit's "Open Link in New
/// Window". Each new item says where the page goes (`pendingPlacement`) as it is chosen, then asks WebKit to open the link as its own
/// item would.
final class SunsetWebView: WKWebView {
    /// Where the next page this view's menu asks for goes; read and cleared when WebKit asks for it.
    var pendingPlacement: WebPlacement?
    /// The link menu offers a private tab (not in a page that is private already).
    var offersPrivateTab = true
    /// It took the keyboard (a click in the page): its pane is the focused one.
    var onFocus: () -> Void = {}

    // Covered by the command bar's backdrop: no hover, no pointer shape (t232).
    override func mouseMoved(with event: NSEvent) {
        if !PointerShield.isShielded(window) { super.mouseMoved(with: event) }
    }

    override func mouseEntered(with event: NSEvent) {
        if !PointerShield.isShielded(window) { super.mouseEntered(with: event) }
    }

    override func cursorUpdate(with event: NSEvent) {
        if !PointerShield.isShielded(window) { super.cursorUpdate(with: event) }
    }

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
            })
        else { return }
        let original = menu.items[index]
        menu.removeItem(at: index)
        for (offset, item) in linkItems(replacing: original).enumerated() { menu.insertItem(item, at: index + offset) }
    }

    /// WebKit's item to open the link, as Sunset's items: each WebKit's own retitled, which says where the page goes as it is
    /// chosen, then runs WebKit's action (which asks for the new page at once, before the menu says it closed; n51).
    func linkItems(replacing original: NSMenuItem) -> [NSMenuItem] {
        guard let action = original.action else { return [original] }
        webKitOpen = (action, original.target)
        let choices = offersPrivateTab ? Self.linkChoices : Array(Self.linkChoices.dropLast())
        return choices.enumerated()
            .compactMap { offset, choice in
                guard let item = original.copy() as? NSMenuItem else { return nil }
                item.title = choice.0
                item.identifier = NSUserInterfaceItemIdentifier("sunset.openLink.\(offset)")
                item.action = #selector(chooseLink(_:))
                item.target = self
                item.tag = offset
                item.representedObject = original.representedObject
                return item
            }
    }

    /// WebKit's action and target for opening a link from its menu.
    private var webKitOpen: (action: Selector, target: AnyObject?)?
    /// The link items, in order; an item's tag is its place here (read as it is chosen, whenever the menu closes).
    private static let linkChoices: [(String, WebPlacement)] = [
        ("Open Link in Split Right", .splitRight), ("Open Link in Split Down", .splitDown),
        ("Open Link in New Tab", .tabAfter), ("Open Link in New Window", .window),
        ("Open Link in Private Tab", .privateTab)
    ]

    @objc private func chooseLink(_ item: NSMenuItem) {
        guard Self.linkChoices.indices.contains(item.tag) else { return }
        pendingPlacement = Self.linkChoices[item.tag].1
        guard let open = webKitOpen else { return }
        NSApp.sendAction(open.action, to: open.target, from: item)
    }
}
