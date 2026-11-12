import AppKit
import SunsetConfig
import SunsetHost
import SunsetPane
import SunsetShell
import SunsetWeb

/// What the menu and the sidebar do that needs the SwiftUI environment (opening a window): the scene hands them over once it has them.
@MainActor
final class AppActions {
    static let shared = AppActions()

    /// Opens a new terminal window (which joins the key window's tab group when the system tabs are on).
    var openTerminalWindow: () -> Void = {}

    /// The window a new tab is to join, set while the new window is being made (system tabs): `NSWindow.tabbingMode` only takes effect for a window that is
    /// not yet on screen, and SwiftUI shows it first, so the new window is added to the parent's group explicitly (`addTabbedWindow(_:ordered:)`).
    var tabParent: NSWindow?
    /// How many windows that are about to appear are to join `tabParent` (one for a new tab; several when tabs are spread into windows).
    var joinsRemaining = 0
    /// Contents that run already and are waiting for a window to show them (the presentation changed from one window of tabs to a window each).
    var handoff: [any PaneContent] = []
    /// The next window to appear is a private one (File > New Private Window, web step h).
    var pendingPrivateWindow = false

    /// A new tab in the way the configuration shows tabs: a tab of the window with the built-in bar, a new window that joins the group with system tabs,
    /// a plain window with none. Of the kind the focused pane is (the owner's answer in web step a): a page makes a new empty page, a terminal a terminal;
    /// `kind` asks for one.
    /// Asks which kind of tab to make (Shift-Cmd-T).
    func chooseKind() { TabRegistry.shared.tabs(for: TabRegistry.shared.actingWindow)?.choosingKind = true }

    func newTab(kind: PaneDescriptor? = nil) {
        let tabs = TabRegistry.shared.tabs(for: TabRegistry.shared.actingWindow)
        // A private page's new tab is private too.
        let focusedPage = tabs?.selectedContent as? WebContent
        let samePage = focusedPage.map { $0.isPrivate ? PaneContentKinds.newPrivatePage : PaneContentKinds.newPage }
        let wanted = kind ?? samePage
        if AppConfiguration.shared.presentation.hostsTabsInWindow, let tabs {
            tabs.newTab(wanted)
        } else if let wanted, wanted.kind != PaneDescriptor.terminalKind {
            // A window of its own: a page waits for it as content handed over.
            let page = PaneContentKinds.make(wanted) { SessionStore.shared.scheduleSave() }
            handoff.append(page)
            tabParent = AppConfiguration.shared.presentation.usesSystemTabbing ? TabRegistry.shared.actingWindow : nil
            joinsRemaining = tabParent == nil ? 0 : 1
            openTerminalWindow()
        } else {
            tabParent = AppConfiguration.shared.presentation.usesSystemTabbing ? TabRegistry.shared.actingWindow : nil
            joinsRemaining = tabParent == nil ? 0 : 1
            openTerminalWindow()
        }
    }

    /// A terminal window has appeared: if a tab was asked for, it joins the parent's group and becomes the selected tab.
    func joinPendingTab(_ window: NSWindow) {
        guard let parent = tabParent, joinsRemaining > 0, parent !== window, parent.isVisible else { return }
        joinsRemaining -= 1
        if joinsRemaining == 0 { tabParent = nil }
        parent.addTabbedWindow(window, ordered: .above)
        window.makeKeyAndOrderFront(nil)
        ChromeView.syncTabBar(of: window, presentation: AppConfiguration.shared.presentation)
    }

    private var keyTabs: TabsModel? { TabRegistry.shared.tabs(for: TabRegistry.shared.actingWindow) }

    /// Closes the current tab: the tab of the built-in bar, or the window (which is the tab) with system tabs.
    func closeTab() {
        if let tabs = keyTabs {
            tabs.closeSelected()
        } else {
            TabRegistry.shared.actingWindow?.performClose(nil)
        }
    }

    func closeWindow() { TabRegistry.shared.actingWindow?.performClose(nil) }

    /// Renames what the key window shows: in place when the sidebar is docked (R3 step c), with the dialog otherwise (the built-in bar's rows are small).
    func renameTab() {
        guard let tabs = keyTabs else { return }
        if AppConfiguration.shared.configuration.sidebarDocked {
            if let entry = tabs.workspace.selectedEntry {
                tabs.renamingRow = .node(entry)
            } else if let item = tabs.workspace.selectedID {
                tabs.renamingRow = .tab(item)
            }
        } else if let item = tabs.workspace.selectedID {
            tabs.beginRename(item: item)
        }
    }

    /// ⌘L: the command bar of the key window (searching its tabs).
    func toggleCommandBar() { keyTabs?.toggleBar() }

    /// ⌘+ and ⌘−: the font of the key window one point bigger or smaller, ⌘0 back to the configured size. Not written to the file.
    /// Cmd-+ and Cmd--: the focused page's zoom, else the terminal's font.
    func zoomFont(by points: Double) {
        guard let tabs = keyTabs else { return }
        if let page = tabs.selectedContent as? WebContent { return page.zoom(by: points > 0 ? 1 : -1) }
        tabs.fontZoom.step(by: points, base: AppConfiguration.shared.configuration.font.size)
    }

    func resetFontZoom() {
        if let page = keyTabs?.selectedContent as? WebContent { return page.resetZoom() }
        keyTabs?.fontZoom.reset()
    }

    // MARK: Splits (the panes of the key window's selected tab)

    /// A new terminal beside the focused one, on `edge`.
    func split(_ edge: PaneEdge) { keyTabs?.newSplit(edge) }

    func focusNextPane() { keyTabs?.focusNextPane() }
    func focusPreviousPane() { keyTabs?.focusPreviousPane() }

    /// The focused pane of a split leaves it, to a tab of its own.
    func moveFocusedPaneToTab() {
        if let tabs = keyTabs, let pane = tabs.workspace.selectedPane { tabs.detachIntoTab(pane) }
    }

    func selectNextTab() {
        if AppConfiguration.shared.presentation.hostsTabsInWindow, let tabs = keyTabs {
            tabs.selectNext()
        } else {
            NSApp.sendAction(#selector(NSWindow.selectNextTab(_:)), to: nil, from: nil)
        }
    }

    func selectPreviousTab() {
        if AppConfiguration.shared.presentation.hostsTabsInWindow, let tabs = keyTabs {
            tabs.selectPrevious()
        } else {
            NSApp.sendAction(#selector(NSWindow.selectPreviousTab(_:)), to: nil, from: nil)
        }
    }

    /// The nth tab (counting from 1; 9 means the last, as in browsers).
    func selectTab(number: Int) {
        if AppConfiguration.shared.presentation.hostsTabsInWindow, let tabs = keyTabs {
            tabs.select(index: number == 9 ? tabs.workspace.count - 1 : number - 1)
        } else if let group = TabRegistry.shared.actingWindow?.tabGroup {
            let index = number == 9 ? group.windows.count - 1 : number - 1
            if group.windows.indices.contains(index) { TabRegistry.shared.select(group.windows[index]) }
        }
    }
}
