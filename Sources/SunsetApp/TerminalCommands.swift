import AppKit
import SunsetCore
import SunsetPane
import SunsetShell
import SunsetTerminal
import SunsetWeb
import SwiftUI

/// The menus. Copy, Paste and Select All are the system's own items: the view that has the keyboard answers them (`TerminalNSView+Pasteboard`).
struct TerminalCommands: Commands {
    @FocusedValue(\.terminalModel) private var model
    @FocusedValue(\.webPage) private var focusedPage
    /// The page the History and Find items act on: the focused one, else (Sunset not active) the acting window's.
    private var page: WebContent? {
        focusedPage ?? (TabRegistry.shared.tabs(for: TabRegistry.shared.actingWindow)?.selectedContent as? WebContent)
    }

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Window") { AppActions.shared.openTerminalWindow() }.keyboardShortcut("n")
            Button("New Tab") { AppActions.shared.newTab() }.keyboardShortcut("t")
            Button("New Tab of Kind\u{2026}") { AppActions.shared.chooseKind() }
                .keyboardShortcut("t", modifiers: [.command, .shift])
            Divider()
            Button("New Private Window") { AppActions.shared.newPrivateWindow() }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            Button("New Private Tab") { AppActions.shared.newTab(kind: PaneContentKinds.newPrivatePage) }
                .keyboardShortcut("n", modifiers: [.command, .shift, .option])
        }
        CommandGroup(replacing: .saveItem) {
            Button("Close") { AppActions.shared.closeTab() }.keyboardShortcut("w")
            Button("Close Window") { AppActions.shared.closeWindow() }
                .keyboardShortcut("w", modifiers: [.command, .shift])
        }
        CommandGroup(after: .textEditing) {
            Button("Command Bar") { AppActions.shared.toggleCommandBar() }.keyboardShortcut("l")
            PageFindCommands(page: page)
        }
        CommandGroup(after: .toolbar) {
            Button(page == nil ? "Bigger" : "Zoom In") { AppActions.shared.zoomFont(by: 1) }.keyboardShortcut("+")
            Button(page == nil ? "Smaller" : "Zoom Out") { AppActions.shared.zoomFont(by: -1) }.keyboardShortcut("-")
            Button("Actual Size") { AppActions.shared.resetFontZoom() }.keyboardShortcut("0")
            Divider()
            Button("Previous Prompt") { model?.jumpToPrompt(.previous) }
                .keyboardShortcut(.upArrow)
                .disabled(model == nil)
            Button("Next Prompt") { model?.jumpToPrompt(.next) }
                .keyboardShortcut(.downArrow)
                .disabled(model == nil)
        }
        CommandMenu("Panes") {
            Button("New Terminal Tab") { AppActions.shared.newTab(kind: PaneDescriptor.terminal(directory: nil)) }
            Button("New Web Page") { AppActions.shared.newTab(kind: PaneContentKinds.newPage) }
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
        }
        CommandMenu("History") {
            Button("Back") { page?.goBack() }.keyboardShortcut("[").disabled(page?.canGoBack != true)
            Button("Forward") { page?.goForward() }.keyboardShortcut("]").disabled(page?.canGoForward != true)
            Divider()
            Button("Reload Page") { page?.reload() }.keyboardShortcut("r").disabled(page?.url == nil)
            Button("Reload Page Without Cache") { page?.reload(fromOrigin: true) }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .disabled(page?.url == nil)
            Button("Stop") { page?.stopLoading() }.keyboardShortcut(".").disabled(page?.isLoading != true)
            // The page's address field, wherever `web.address` puts it (the window's bar comes out for it), ready to type in.
            Button("Open Address") { page?.wantsAddress = true }.disabled(page == nil)
            HistoryMenuItems(page: page)
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
        }
    }
}
