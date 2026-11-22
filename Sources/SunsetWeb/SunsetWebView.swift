import AppKit
import SunsetRuntime
import SunsetShell
import SunsetWebModel
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
    /// The engine the text menu's Search the Web uses, and what to do with its address (open it as a page the page opened).
    var searchEngine: () -> SearchEngine? = { nil }
    var onSearch: (URL) -> Void = { _ in }
    /// The words selected in the page, read as the item is chosen (WebKit's own item gives them to the system's browser).
    var searchWords: () async -> String? = { nil }
    /// Where its tasks run (through the seam, not `Task {}`).
    var runtime = Runtime.live

    // Covered by the command bar's backdrop: no hover, no pointer shape.
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
        openedActions = [:]
        retitleOpenedItems(in: menu)
        retitleSearchItem(in: menu)
        guard
            let index = menu.items.firstIndex(where: {
                $0.identifier?.rawValue == "WKMenuItemIdentifierOpenLinkInNewWindow"
            })
        else { return }
        let original = menu.items[index]
        menu.removeItem(at: index)
        for (offset, item) in linkItems(replacing: original).enumerated() { menu.insertItem(item, at: index + offset) }
    }

    /// WebKit's Open Image, Video or Frame in New Window: the page opens shown in a tab after this one (`WebPlacement.opened`),
    /// and the item says so. Matched by WebKit's identifiers' shape, `…InNewWindow`; the link's has Sunset's own items. Chosen,
    /// each says so before WebKit's action runs: WebKit asks for the page as one the person did not open (probed 2026-11-20),
    /// and the pop-up rule stopped it.
    func retitleOpenedItems(in menu: NSMenu) {
        for item in menu.items {
            guard let identifier = item.identifier?.rawValue, identifier.hasPrefix("WKMenuItemIdentifier"),
                identifier.hasSuffix("InNewWindow"), identifier != "WKMenuItemIdentifierOpenLinkInNewWindow",
                item.title.hasSuffix("New Window"), let action = item.action
            else { continue }
            item.title = String(item.title.dropLast("New Window".count)) + "New Tab"
            openedActions[ObjectIdentifier(item)] = (action, item.target)
            item.action = #selector(chooseOpened(_:))
            item.target = self
        }
    }

    /// The text menu's Search with Google (WebKit's, which gives the words to the system's default browser: seen 2026-11-20,
    /// Safari came forward): searches with Sunset's engine, in a tab after the page, shown.
    func retitleSearchItem(in menu: NSMenu) {
        guard let engine = searchEngine(),
            let item = menu.items.first(where: { $0.identifier?.rawValue == "WKMenuItemIdentifierSearchWeb" })
        else { return }
        item.title = "Search with \(engine.name)"
        item.action = #selector(chooseSearch(_:))
        item.target = self
    }

    @objc private func chooseSearch(_ item: NSMenuItem) {
        runtime.task { @MainActor [weak self] in
            guard let self, let engine = searchEngine(), let words = await searchWords(),
                !words.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                let address = engine.searchURL(words.trimmingCharacters(in: .whitespacesAndNewlines))
            else { return }
            onSearch(address)
        }
    }

    /// WebKit's actions for the open items of the menu shown, by item.
    private var openedActions: [ObjectIdentifier: (action: Selector, target: AnyObject?)] = [:]

    @objc private func chooseOpened(_ item: NSMenuItem) {
        guard let open = openedActions[ObjectIdentifier(item)] else { return }
        pendingPlacement = .opened
        NSApp.sendAction(open.action, to: open.target, from: item)
    }

    /// WebKit's item to open the link, as Sunset's items: each WebKit's own retitled, which says where the page goes as it is
    /// chosen, then runs WebKit's action (which asks for the new page at once, before the menu says it closed).
    func linkItems(replacing original: NSMenuItem) -> [NSMenuItem] {
        guard let action = original.action else { return [original] }
        webKitOpen = (action, original.target)
        let choices = offersPrivateTab ? Self.linkChoices : Array(Self.linkChoices.dropLast())
        return choices.enumerated()
            .compactMap { offset, choice in
                guard let item = original.copy() as? NSMenuItem else { return nil }
                item.title = choice.0
                // The tag stays WebKit's: its action tells its items apart by it (an item with the place's index as its tag
                // ran another action, or none; seen 2026-11-20). The place is read from the identifier.
                item.identifier = NSUserInterfaceItemIdentifier("sunset.openLink.\(offset)")
                item.action = #selector(chooseLink(_:))
                item.target = self
                item.representedObject = original.representedObject
                return item
            }
    }

    /// WebKit's action and target for opening a link from its menu.
    private var webKitOpen: (action: Selector, target: AnyObject?)?
    /// The link items, in order; an item's identifier ends with its place here (read as it is chosen, whenever the menu closes).
    private static let linkChoices: [(String, WebPlacement)] = [
        ("Open Link in Split Right", .splitRight), ("Open Link in Split Down", .splitDown),
        ("Open Link in New Tab", .tabAfter), ("Open Link in New Window", .window),
        ("Open Link in Private Tab", .privateTab)
    ]

    @objc private func chooseLink(_ item: NSMenuItem) {
        guard let raw = item.identifier?.rawValue, raw.hasPrefix("sunset.openLink."),
            let index = Int(raw.dropFirst("sunset.openLink.".count)), Self.linkChoices.indices.contains(index)
        else { return }
        pendingPlacement = Self.linkChoices[index].1
        guard let open = webKitOpen else { return }
        NSApp.sendAction(open.action, to: open.target, from: item)
    }
}
