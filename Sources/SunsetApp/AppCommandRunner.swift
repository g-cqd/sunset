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

    // A dispatch table: one case per command, as long as the table is.
    // swiftlint:disable:next cyclomatic_complexity function_body_length - one case per command of the table
    static func run(_ id: AppCommand.ID, on target: Target = .acting) {
        let actions = AppActions.shared
        let page = target.page
        switch id {
            case .newWindow: actions.openTerminalWindow()
            case .newTab: actions.newTab()
            case .newTabOfKind: actions.chooseKind()
            case .newPrivateWindow: actions.newPrivateWindow()
            case .newPrivateTab: actions.newTab(kind: PaneContentKinds.newPrivatePage)
            case .newDocument: actions.newDocument()
            case .openFile: actions.openFile()
            case .closeTab: actions.closeTab()
            case .closeOtherTabs: actions.closeOtherTabs()
            case .closeWindow: actions.closeWindow()
            case .print: page?.printPage()
            case .importFromBrowser: actions.importFromBrowser()
            case .commandBar: actions.toggleCommandBar()
            case .zoomIn: actions.zoomFont(by: 1)
            case .zoomOut: actions.zoomFont(by: -1)
            case .actualSize: actions.resetFontZoom()
            case .previousPrompt: target.terminal?.jumpToPrompt(.previous)
            case .nextPrompt: target.terminal?.jumpToPrompt(.next)
            case .library: actions.toggleLibrary()
            case .documents, .history, .downloads, .passwords: showLibrary(id)
            case .settings: actions.showSettings()
            case .help: actions.showHelp()
            case .splitRight: actions.split(.right)
            case .splitDown: actions.split(.bottom)
            case .nextPane: actions.focusNextPane()
            case .previousPane: actions.focusPreviousPane()
            case .movePaneToTab: actions.moveFocusedPaneToTab()
            case .renameTab: actions.renameTab()
            case .togglePinned: actions.togglePinned()
            case .toggleFavorite: actions.toggleFavorite()
            case .nextTab: actions.selectNextTab()
            case .previousTab: actions.selectPreviousTab()
            case .newSpace: actions.spaceTabs?.newSpace()
            case .editSpace: if let tabs = actions.spaceTabs { tabs.edit(space: tabs.space) }
            case .deleteSpace: actions.spaceTabs?.deleteSpace()
            case .nextSpace: actions.spaceTabs?.stepSpace(by: 1)
            case .previousSpace: actions.spaceTabs?.stepSpace(by: -1)
            case .back: page?.goBack()
            case .forward: page?.goForward()
            case .reload: page?.reload()
            case .reloadWithoutCache: page?.reload(fromOrigin: true)
            case .forceReload: page?.forceReload()
            case .toggleMute: page?.toggleMuted()
            case .stop: page?.stopLoading()
            case .openAddress: page?.wantsAddress = true
            case .toggleInspector: page?.toggleInspector()
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
