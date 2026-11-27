import AppKit
import SunsetRuntime
import SunsetShell
import SunsetWebModel
import WebKit

/// The page's view: WebKit's, with Sunset's link menu ("Open Link in New Tab" plus an "Open Link In" submenu for Split
/// Right, Split Down, New Window, Private Tab) in place of WebKit's "Open Link in New Window", and full page actions
/// (Back, Forward, Copy Page Address, Print Page…) on the page background menu where WebKit omits them.
final class SunsetWebView: WKWebView {
    /// A page's own long and deep presses (Look Up, a link's preview) stay its own (`LongPressMenus`).
    override var acceptsLongPressItself: Bool {
        true
    }

    /// Where the next page this view's menu asks for goes; read and cleared when WebKit asks for it.
    var pendingPlacement: WebPlacement?
    /// The link menu offers a private tab (not in a page that is private already).
    var offersPrivateTab = true
    /// It took the keyboard (a click in the page): its pane is the focused one.
    var onFocus: () -> Void = {}
    /// Page navigation state and actions for the background context menu.
    var pageNavState: () -> (canGoBack: Bool, canGoForward: Bool, hasURL: Bool) = { (false, false, false) }
    var onNavigateBack: () -> Void = {}
    var onNavigateForward: () -> Void = {}
    var onCopyPageAddress: () -> Void = {}
    var onPrintPage: () -> Void = {}
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
        addPageItems(to: menu)
        if let index = menu.items.firstIndex(where: {
            $0.identifier?.rawValue == "WKMenuItemIdentifierOpenLinkInNewWindow"
        }) {
            let original = menu.items[index]
            menu.removeItem(at: index)
            for (offset, item) in linkItems(replacing: original).enumerated() {
                menu.insertItem(item, at: index + offset)
            }
        }
        collapseSeparators(in: menu)
    }

    /// WebKit's actions for the open items of the menu shown, by item.
    var openedActions: [ObjectIdentifier: (action: Selector, target: AnyObject?)] = [:]
    /// WebKit's action and target for opening a link from its menu.
    var webKitOpen: (action: Selector, target: AnyObject?)?
}
