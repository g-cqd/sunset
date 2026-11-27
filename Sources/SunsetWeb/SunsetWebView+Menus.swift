import AppKit
import SunsetRuntime
import SunsetWebModel

/// Menu customisation for `SunsetWebView`: compact link opening ("Open Link in New Tab" + "Open Link In" submenu),
/// page-level Back / Forward / Copy Page Address / Print Page… items, Search engine retitling, and separator cleanup.
extension SunsetWebView {
    /// Index 0 is the top-level item; indices 1... live inside the "Open Link In" submenu.
    static let linkChoices: [(String, WebPlacement)] = [
        ("Open Link in New Tab", .tabAfter),
        ("Split Right", .splitRight),
        ("Split Down", .splitDown),
        ("New Window", .window),
        ("Private Tab", .privateTab)
    ]

    /// WebKit's Open Image, Video or Frame in New Window: the page opens shown in a tab after this one (`WebPlacement.opened`),
    /// and the item says so. Matched by WebKit's identifiers' shape, `…InNewWindow`; the link's has Sunset's own items.
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

    /// The text menu's Search with Google: searches with Sunset's engine, in a tab after the page, shown.
    func retitleSearchItem(in menu: NSMenu) {
        guard let engine = searchEngine(),
            let item = menu.items.first(where: { $0.identifier?.rawValue == "WKMenuItemIdentifierSearchWeb" })
        else { return }
        item.title = "Search with \(engine.name)"
        item.action = #selector(chooseSearch(_:))
        item.target = self
    }

    /// On the page background menu (where WebKit includes `WKMenuItemIdentifierReload` and omits Back, Forward, Copy
    /// Address and Print), fills in Back and Forward when navigable, plus Copy Page Address and Print Page….
    func addPageItems(to menu: NSMenu) {
        guard
            let reloadIndex = menu.items.firstIndex(where: {
                $0.identifier?.rawValue == "WKMenuItemIdentifierReload"
            })
        else { return }
        let state = pageNavState()
        var at = reloadIndex
        let existingIDs = Set(menu.items.compactMap { $0.identifier?.rawValue })
        if state.canGoBack || state.canGoForward,
            !existingIDs.contains("WKMenuItemIdentifierGoBack"),
            !existingIDs.contains("WKMenuItemIdentifierGoForward")
        {
            if state.canGoBack {
                let back = ClosureMenuItem(title: "Back", run: onNavigateBack)
                back.identifier = NSUserInterfaceItemIdentifier("sunset.page.back")
                menu.insertItem(back, at: at)
                at += 1
            }
            if state.canGoForward {
                let forward = ClosureMenuItem(title: "Forward", run: onNavigateForward)
                forward.identifier = NSUserInterfaceItemIdentifier("sunset.page.forward")
                menu.insertItem(forward, at: at)
                at += 1
            }
        }
        guard state.hasURL else { return }
        var afterReload = at + 1
        menu.insertItem(.separator(), at: afterReload)
        afterReload += 1
        let copyURL = ClosureMenuItem(title: "Copy Page Address", run: onCopyPageAddress)
        copyURL.identifier = NSUserInterfaceItemIdentifier("sunset.page.copyAddress")
        menu.insertItem(copyURL, at: afterReload)
        afterReload += 1
        let printItem = ClosureMenuItem(title: "Print Page\u{2026}", run: onPrintPage)
        printItem.identifier = NSUserInterfaceItemIdentifier("sunset.page.print")
        menu.insertItem(printItem, at: afterReload)
    }

    /// Removes leading, trailing and consecutive separator items WebKit leaves behind for unused menu slots.
    func collapseSeparators(in menu: NSMenu) {
        var previousSeparator = true
        for item in Array(menu.items) {
            if item.isSeparatorItem {
                if previousSeparator {
                    menu.removeItem(item)
                } else {
                    previousSeparator = true
                }
            } else {
                previousSeparator = false
            }
        }
        if let last = menu.items.last, last.isSeparatorItem {
            menu.removeItem(last)
        }
    }

    /// Replaces WebKit's "Open Link in New Window" with top-level "Open Link in New Tab" plus an "Open Link In" submenu
    /// holding Split Right, Split Down, New Window, and (when allowed) Private Tab.
    func linkItems(replacing original: NSMenuItem) -> [NSMenuItem] {
        guard let action = original.action else { return [original] }
        webKitOpen = (action, original.target)
        guard let newTab = makeLinkChoice(from: original, index: 0) else { return [original] }
        let end = offersPrivateTab ? Self.linkChoices.count : Self.linkChoices.count - 1
        let submenu = NSMenu(title: "Open Link In")
        for index in 1 ..< end {
            if let child = makeLinkChoice(from: original, index: index) {
                submenu.addItem(child)
            }
        }
        let parent = NSMenuItem(title: "Open Link In", action: nil, keyEquivalent: "")
        parent.identifier = NSUserInterfaceItemIdentifier("sunset.openLink.submenu")
        parent.submenu = submenu
        return [newTab, parent]
    }

    private func makeLinkChoice(from original: NSMenuItem, index: Int) -> NSMenuItem? {
        guard let item = original.copy() as? NSMenuItem else { return nil }
        item.title = Self.linkChoices[index].0
        // The tag stays WebKit's: its action tells its items apart by it (`forwardContextMenuAction:`).
        item.identifier = NSUserInterfaceItemIdentifier("sunset.openLink.\(index)")
        item.action = #selector(chooseLink(_:))
        item.target = self
        item.representedObject = original.representedObject
        return item
    }

    @objc func chooseSearch(_ item: NSMenuItem) {
        runtime.task { @MainActor [weak self] in
            guard let self, let engine = searchEngine(), let words = await searchWords(),
                !words.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                let address = engine.searchURL(words.trimmingCharacters(in: .whitespacesAndNewlines))
            else { return }
            onSearch(address)
        }
    }

    @objc func chooseOpened(_ item: NSMenuItem) {
        guard let open = openedActions[ObjectIdentifier(item)] else { return }
        pendingPlacement = .opened
        NSApp.sendAction(open.action, to: open.target, from: item)
    }

    @objc func chooseLink(_ item: NSMenuItem) {
        guard let raw = item.identifier?.rawValue, raw.hasPrefix("sunset.openLink."),
            let index = Int(raw.dropFirst("sunset.openLink.".count)), Self.linkChoices.indices.contains(index)
        else { return }
        pendingPlacement = Self.linkChoices[index].1
        guard let open = webKitOpen else { return }
        NSApp.sendAction(open.action, to: open.target, from: item)
    }
}
