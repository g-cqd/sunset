import SunsetConfig
import SunsetCore
import SunsetPane
import SunsetShellModel
import SunsetTerminalModel
import SunsetWeb

/// Runs a command of the table (`AppCommand`) as its menu item does: from the menus with what has the keyboard, from the
/// command bar with what the acting window shows.
@MainActor enum AppCommandRunner {
    /// What a command acts on besides the app: the page and the terminal shown.
    @MainActor struct Target {
        var page: WebContent?
        var terminal: TerminalModel?

        /// What the acting window shows.
        static var acting: Self {
            let tabs = TabRegistry.shared.tabs(for: TabRegistry.shared.actingWindow)
            return Self(page: tabs?.selectedContent as? WebContent, terminal: tabs?.selectedTerminal)
        }
    }

    static func run(_ id: AppCommand.ID, on target: Target = .acting) {
        if runOnPage(id, target.page) || runOnTabs(id, target) { return }
        runOnApp(id)
    }

    /// The History menu's and Print: what the page does.
    private static func runOnPage(_ id: AppCommand.ID, _ page: WebContent?) -> Bool {
        switch id {
            case .back: page?.goBack()
            case .forward: page?.goForward()
            case .reload, .reloadWithoutCache: page?.reload(fromOrigin: id == .reloadWithoutCache)
            case .forceReload: page?.forceReload()
            case .toggleMute: page?.toggleMuted()
            case .stop: page?.stopLoading()
            case .openAddress: page?.wantsAddress = true
            case .toggleInspector: page?.toggleInspector()
            case .print: page?.printPage()
            default: return false
        }
        return true
    }

    /// What a window's tabs, panes, Spaces and terminal do.
    private static func runOnTabs(_ id: AppCommand.ID, _ target: Target) -> Bool {
        let actions = AppActions.shared
        switch id {
            case .previousPrompt, .nextPrompt: target.terminal?.jumpToPrompt(id == .nextPrompt ? .next : .previous)
            case .splitRight, .splitDown: actions.split(id == .splitDown ? .bottom : .right)
            case .nextPane, .previousPane: id == .nextPane ? actions.focusNextPane() : actions.focusPreviousPane()
            case .nextTab, .previousTab: id == .nextTab ? actions.selectNextTab() : actions.selectPreviousTab()
            case .nextSpace, .previousSpace: actions.spaceTabs?.stepSpace(by: id == .nextSpace ? 1 : -1)
            case .newSpace: actions.spaceTabs?.newSpace()
            case .editSpace: if let tabs = actions.spaceTabs { tabs.edit(space: tabs.space) }
            case .deleteSpace: actions.spaceTabs?.deleteSpace()
            case .zoomIn, .zoomOut: actions.zoomFont(by: id == .zoomIn ? 1 : -1)
            case .documents, .history, .downloads, .passwords: showLibrary(id)
            case .movePaneToTab: actions.moveFocusedPaneToTab()
            case .renameTab: actions.renameTab()
            case .togglePinned: actions.togglePinned()
            case .toggleFavorite: actions.toggleFavorite()
            default: return false
        }
        return true
    }

    /// What the app does: windows, tabs made and closed, its places.
    private static func runOnApp(_ id: AppCommand.ID) {
        let actions = AppActions.shared
        switch id {
            case .newWindow: actions.openTerminalWindow()
            case .newTab, .newPrivateTab: actions.newTab(kind: id == .newTab ? nil : PaneContentKinds.newPrivatePage)
            case .newTabOfKind: actions.chooseKind()
            case .newPrivateWindow: actions.newPrivateWindow()
            case .newDocument: actions.newDocument()
            case .openFile: actions.openFile()
            case .closeTab, .closeOtherTabs: id == .closeTab ? actions.closeTab() : actions.closeOtherTabs()
            case .closeWindow: actions.closeWindow()
            case .importFromBrowser: actions.importFromBrowser()
            case .commandBar: actions.toggleCommandBar()
            case .actualSize: actions.resetFontZoom()
            case .library: actions.toggleLibrary()
            case .settings: actions.showSettings()
            case .help: actions.showHelp()
            default: break
        }
    }

    /// Whether it would do something now: its menu item is dimmed, and the command bar leaves it out, when not.
    static func isEnabled(_ id: AppCommand.ID, on target: Target = .acting) -> Bool {
        let page = target.page
        let manySpaces = AppSpaces.all.spaces.count > 1
        switch id {
            case .print, .reload, .reloadWithoutCache, .forceReload: return page?.url != nil
            case .previousPrompt, .nextPrompt: return target.terminal != nil
            case .editSpace, .deleteSpace, .nextSpace, .previousSpace: return manySpaces
            case .back: return page?.canGoBack == true
            case .forward: return page?.canGoForward == true
            case .toggleMute: return page?.sound != nil
            case .stop: return page?.isLoading == true
            case .openAddress: return page != nil
            case .toggleInspector: return page?.settings.developer == true
            case .library: return AppConfiguration.shared.configuration.sidebar.library
            default: return true
        }
    }

    /// The Library's list it names, in the acting window.
    private static func showLibrary(_ id: AppCommand.ID) {
        guard let section = id.librarySection else { return }
        TabRegistry.shared.tabs(for: TabRegistry.shared.actingWindow)?.sections.show(library: section)
    }
}
