import AppKit
import SunsetCore
import SunsetMarkdown
import SunsetPane
import SunsetShell
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
    private var document: DocumentContent? { focusedDocument ?? AppActions.shared.frontDocument }
    /// The page the History and Find items act on: the focused one, else (Sunset not active) the acting window's.
    private var page: WebContent? {
        focusedPage ?? (TabRegistry.shared.tabs(for: TabRegistry.shared.actingWindow)?.selectedContent as? WebContent)
    }

    var body: some Commands {
        let open = openWindow
        let _ = AppActions.shared.opensWindows { open(id: "terminal") }
        // What is of a scope that is off is not in the menus (roadmap 0033).
        let scopes = AppScopes.current
        // The settings are a tab of the window (roadmap 0032): there is no Settings scene to give this item.
        // Help is a tab of its own window (roadmap 0041 E; the owner, 2026-11-17: a window reusing the shell).
        CommandGroup(replacing: .help) {
            Button("Sunset Help") { AppActions.shared.showHelp() }.keyboardShortcut("?", modifiers: .command)
        }
        CommandGroup(replacing: .appSettings) {
            Button("Settings\u{2026}") { AppActions.shared.showSettings() }.keyboardShortcut(",")
        }
        CommandGroup(replacing: .newItem) {
            Button("New Window") { AppActions.shared.openTerminalWindow() }.keyboardShortcut("n")
            Button("New Tab") { AppActions.shared.newTab() }.keyboardShortcut("t")
            if scopes.terminal, scopes.web {
                Button("New Tab of Kind\u{2026}") { AppActions.shared.chooseKind() }
                    .keyboardShortcut("t", modifiers: [.command, .shift])
            }
            if scopes.web {
                Divider()
                Button("New Private Window") { AppActions.shared.newPrivateWindow() }
                    .keyboardShortcut("n", modifiers: [.command, .shift])
                Button("New Private Tab") { AppActions.shared.newTab(kind: PaneContentKinds.newPrivatePage) }
                    .keyboardShortcut("n", modifiers: [.command, .shift, .option])
            }
            if scopes.documents {
                Divider()
                Button("New Document") { AppActions.shared.newDocument() }
                Button("Open File\u{2026}") { AppActions.shared.openFile() }.keyboardShortcut("o")
            }
        }
        CommandGroup(replacing: .saveItem) {
            Button("Close") { AppActions.shared.closeTab() }.keyboardShortcut("w")
            Button("Close Window") { AppActions.shared.closeWindow() }
                .keyboardShortcut("w", modifiers: [.command, .shift])
            if scopes.documents {
                Button("Save") { document?.save() }.keyboardShortcut("s").disabled(document == nil)
            }
        }
        CommandGroup(replacing: .printItem) {
            if scopes.web {
                Button("Print\u{2026}") { page?.printPage() }.keyboardShortcut("p").disabled(page?.url == nil)
            }
        }
        CommandGroup(after: .textEditing) {
            Button("Command Bar") { AppActions.shared.toggleCommandBar() }.keyboardShortcut("l")
            if scopes.web { PageFindCommands(page: page) }
        }
        CommandGroup(after: .toolbar) {
            Button(page == nil ? "Bigger" : "Zoom In") { AppActions.shared.zoomFont(by: 1) }.keyboardShortcut("+")
            Button(page == nil ? "Smaller" : "Zoom Out") { AppActions.shared.zoomFont(by: -1) }.keyboardShortcut("-")
            Button("Actual Size") { AppActions.shared.resetFontZoom() }.keyboardShortcut("0")
            if scopes.documents {
                Divider()
                DocumentCommands(document: document)
            }
            Divider()
            SectionCommands(scopes: scopes)
            if scopes.terminal {
                Divider()
                Button("Previous Prompt") { model?.jumpToPrompt(.previous) }
                    .keyboardShortcut(.upArrow)
                    .disabled(model == nil)
                Button("Next Prompt") { model?.jumpToPrompt(.next) }
                    .keyboardShortcut(.downArrow)
                    .disabled(model == nil)
            }
        }
        CommandMenu("Panes") {
            if scopes.terminal {
                Button("New Terminal Tab") { AppActions.shared.newTab(kind: PaneDescriptor.terminal(directory: nil)) }
            }
            if scopes.web { Button("New Web Page") { AppActions.shared.newTab(kind: PaneContentKinds.newPage) } }
            Divider()
            Button("Split Right") { AppActions.shared.split(.right) }.keyboardShortcut("d")
            Button("Split Down") { AppActions.shared.split(.bottom) }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            Divider()
            Button("Next Pane") { AppActions.shared.focusNextPane() }
                .keyboardShortcut("]", modifiers: [.command, .option])
            Button("Previous Pane") { AppActions.shared.focusPreviousPane() }
                .keyboardShortcut("[", modifiers: [.command, .option])
            Divider()
            Button("Move Pane to Its Own Tab") { AppActions.shared.moveFocusedPaneToTab() }
            Divider()
            Button("Rename Tab…") { AppActions.shared.renameTab() }
            Button("Pin or Unpin Tab") { AppActions.shared.togglePinned() }
            Button("Add to or Remove from Favorites") { AppActions.shared.toggleFavorite() }
        }
        // Not there with the web off (roadmap 0033).
        if scopes.web {
            CommandMenu("History") { history }
        }
        CommandGroup(after: .windowArrangement) {
            Button("Show Next Tab") { AppActions.shared.selectNextTab() }
                .keyboardShortcut("]", modifiers: [.command, .shift])
            Button("Show Previous Tab") { AppActions.shared.selectPreviousTab() }
                .keyboardShortcut("[", modifiers: [.command, .shift])
            ForEach(1 ... 9, id: \.self) { number in
                Button("Tab \(number)") { AppActions.shared.selectTab(number: number) }
                    .keyboardShortcut(KeyEquivalent(Character("\(number)")), modifiers: .command)
            }
            // The acting window kept awake (roadmap 0035 E).
            if let tabs = TabRegistry.shared.tabs(for: TabRegistry.shared.actingWindow) {
                Divider()
                KeepAwakeMenu(tabs: tabs, item: nil)
            }
        }
    }

    /// The History menu's items.
    @ViewBuilder private var history: some View {
        Button("Back") { page?.goBack() }.keyboardShortcut("[").disabled(page?.canGoBack != true)
        Button("Forward") { page?.goForward() }.keyboardShortcut("]").disabled(page?.canGoForward != true)
        Divider()
        Button("Reload Page") { page?.reload() }.keyboardShortcut("r").disabled(page?.url == nil)
        Button("Reload Page Without Cache") { page?.reload(fromOrigin: true) }
            .keyboardShortcut("r", modifiers: [.command, .shift])
            .disabled(page?.url == nil)
        // Its process ended and the page loaded in a new one (n50): for a page stuck loading or hung.
        Button("Force Reload Page") { page?.forceReload() }
            .keyboardShortcut("r", modifiers: [.command, .option])
            .disabled(page?.url == nil)
        Button(page?.sound == .muted ? "Unmute Page" : "Mute Page") { page?.toggleMuted() }
            .disabled(page?.sound == nil)
        Button("Stop") { page?.stopLoading() }.keyboardShortcut(".").disabled(page?.isLoading != true)
        // The page's address field, wherever `web.address` puts it (the window's bar comes out for it), ready to type in.
        Button("Open Address") { page?.wantsAddress = true }.disabled(page == nil)
        HistoryMenuItems(page: page)
    }
}
