import AppKit
import SunsetCore
import SunsetPane
import SwiftUI

/// The menus. Copy, Paste and Select All are the system's own items: the view that has the keyboard answers them (`TerminalNSView+Pasteboard`).
struct TerminalCommands: Commands {
    @FocusedValue(\.terminalModel) private var model

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Window") { AppActions.shared.openTerminalWindow() }.keyboardShortcut("n")
            Button("New Tab") { AppActions.shared.newTab() }.keyboardShortcut("t")
        }
        CommandGroup(replacing: .saveItem) {
            Button("Close") { AppActions.shared.closeTab() }.keyboardShortcut("w")
            Button("Close Window") { AppActions.shared.closeWindow() }
                .keyboardShortcut("w", modifiers: [.command, .shift])
        }
        CommandGroup(after: .textEditing) {
            Button("Command Bar") { AppActions.shared.toggleCommandBar() }.keyboardShortcut("l")
        }
        CommandGroup(after: .toolbar) {
            Button("Bigger") { AppActions.shared.zoomFont(by: 1) }.keyboardShortcut("+")
            Button("Smaller") { AppActions.shared.zoomFont(by: -1) }.keyboardShortcut("-")
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
            Button("New Note") { AppActions.shared.newNote() }
            Button("Rename Tab…") { AppActions.shared.renameTab() }
                .keyboardShortcut("r", modifiers: [.command, .shift])
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
