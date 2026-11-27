import AppKit
import SunsetCore
import SunsetMarkdown
import SunsetPane
import SunsetShell
import SunsetShellModel
import SunsetTerminal
import SunsetWeb
import SwiftUI

/// The menus. Copy, Paste and Select All are the system's own items: the view that has the keyboard answers them (`TerminalNSView+Pasteboard`).
struct TerminalCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    @FocusedValue(\.terminalModel) private var model
    @FocusedValue(\.webPage) private var focusedPage
    @FocusedValue(\.documentPane) private var focusedDocument
    /// The document Save and the view items act on: the focused one, else the acting window's.
    private var document: DocumentContent? {
        focusedDocument ?? AppActions.shared.frontDocument
    }
    /// The page the History and Find items act on: the focused one, else (Sunset not active) the acting window's.
    private var page: WebContent? {
        focusedPage ?? (TabRegistry.shared.tabs(for: TabRegistry.shared.actingWindow)?.selectedContent as? WebContent)
    }
    /// What the table's commands act on: the focused page and terminal.
    private var target: AppCommandRunner.Target {
        AppCommandRunner.Target(page: AppScopes.current.web ? page : nil, terminal: model)
    }

    var body: some Commands {
        let open = openWindow
        let _ = AppActions.shared.opensWindows { open(id: "terminal") }
        // What is of a scope that is off is not in the menus.
        let scopes = AppScopes.current
        // The settings are a tab of the window: there is no Settings scene to give this item. Help is a tab of its own
        // window (a window reusing the shell). Option turns About into the easter egg: the sun's opening again.
        CommandGroup(replacing: .appInfo) {
            Button("About Sunset") { AppActions.shared.showAbout() }
                .modifierKeyAlternate(.option) {
                    Button("Watch the Sunset Again") { WelcomeWindow.shared.watchAgain() }
                }
        }
        CommandGroup(replacing: .help) {
            CommandItem(.help)
            Button("Welcome to Sunset") { WelcomeWindow.shared.open(withOpening: true) }
        }
        CommandGroup(replacing: .appSettings) {
            CommandItem(.settings, title: "Settings\u{2026}")
        }
        CommandGroup(replacing: .newItem) {
            CommandItem(.newWindow)
            CommandItem(.newTab)
            // Every kind that is on: asked whenever more than one is.
            if [scopes.terminal, scopes.web, scopes.documents].filter({ $0 }).count > 1 {
                CommandItem(.newTabOfKind)
            }
            if scopes.web {
                Divider()
                CommandItem(.newPrivateWindow)
                CommandItem(.newPrivateTab)
            }
            if scopes.documents {
                Divider()
                CommandItem(.newDocument)
                CommandItem(.openFile)
            }
            if scopes.web {
                BrowserFileItems()
            }
        }
        CommandGroup(replacing: .saveItem) {
            // Close Other Tabs with Option, as Safari's File menu.
            CommandItem(.closeTab, title: "Close")
                .modifierKeyAlternate(.option) { CommandItem(.closeOtherTabs) }
            CommandItem(.closeWindow)
            if scopes.documents {
                Button("Save") { document?.save() }.keyboardShortcut("s").disabled(document == nil)
            }
        }
        CommandGroup(replacing: .printItem) {
            if scopes.web {
                CommandItem(.print, target: target)
            }
        }
        CommandGroup(after: .textEditing) {
            CommandItem(.commandBar)
            PageFindCommands(page: scopes.web ? page : nil, focusedTerminal: scopes.terminal ? model : nil)
        }
        CommandGroup(after: .toolbar) {
            CommandItem(.zoomIn, title: page == nil ? "Bigger" : nil)
            CommandItem(.zoomOut, title: page == nil ? "Smaller" : nil)
            CommandItem(.actualSize)
            if scopes.documents {
                Divider()
                DocumentCommands(document: document)
            }
            Divider()
            SectionCommands(scopes: scopes)
            if scopes.terminal {
                Divider()
                CommandItem(.previousPrompt, target: target)
                CommandItem(.nextPrompt, target: target)
            }
        }
        CommandMenu("Panes") {
            NewKindButtons(scopes: scopes)
            Divider()
            CommandItem(.splitRight)
            CommandItem(.splitDown)
            Divider()
            CommandItem(.nextPane)
            CommandItem(.previousPane)
            Divider()
            CommandItem(.movePaneToTab)
            Divider()
            CommandItem(.renameTab)
            CommandItem(.togglePinned)
            CommandItem(.toggleFavorite)
        }
        trailingMenus(scopes: scopes)
    }

    /// History and Window tab-switching commands, factored out so `body` stays within the 10-child `CommandsBuilder`
    /// limit on macOS 26.5's SDK (before variadic `buildBlock` existed).
    @CommandsBuilder private func trailingMenus(scopes: Scopes) -> some Commands {
        if scopes.documents {
            // Only the key window's document: never one behind a pop-up or a sheet that has the keyboard.
            CommandMenu("Format") {
                MarkdownFormatMenu(
                    document: TabRegistry.shared.tabs(for: TabRegistry.shared.editingWindow)?.selectedContent
                        as? DocumentContent
                )
            }
        }
        // Not there with the web off.
        if scopes.web {
            CommandMenu("History") { history }
        }
        CommandGroup(after: .windowArrangement) {
            CommandItem(.nextTab)
            CommandItem(.previousTab)
            ForEach(1 ... 9, id: \.self) { number in
                Button("Tab \(number)") { AppActions.shared.selectTab(number: number) }
                    .keyboardShortcut(KeyEquivalent(Character("\(number)")), modifiers: .command)
            }
            // The acting window kept awake.
            if let tabs = TabRegistry.shared.tabs(for: TabRegistry.shared.actingWindow) {
                Divider()
                KeepAwakeMenu(tabs: tabs, item: nil)
            }
        }
    }

    /// The History menu's items.
    @ViewBuilder private var history: some View {
        CommandItem(.back, target: target)
        CommandItem(.forward, target: target)
        Divider()
        // Without the cache with Shift, and Force Reload with Option (its process ended and the page loaded in a new one:
        // for a page stuck loading or hung): one item, as Safari's; each shortcut works whatever is shown.
        CommandItem(.reload, target: target)
            .modifierKeyAlternate(.shift) { CommandItem(.reloadWithoutCache, target: target) }
            .modifierKeyAlternate(.option) { CommandItem(.forceReload, target: target) }
        CommandItem(.toggleMute, title: page?.sound == .muted ? "Unmute Page" : "Mute Page", target: target)
        CommandItem(.stop, title: "Stop", target: target)
        // The page's address field, wherever `web.address` puts it (the window's bar comes out for it), ready to type in.
        CommandItem(.openAddress, target: target)
        // WebKit's inspector, docked beside the page in its pane; Inspect Element opens it too.
        CommandItem(
            .toggleInspector,
            title: page?.isInspectorVisible == true ? "Hide Web Inspector" : "Show Web Inspector",
            target: target
        )
        HistoryMenuItems(page: page)
    }
}
