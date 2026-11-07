import AppKit
import SwiftUI

/// The menu: copy the selection, paste, select all.
struct TerminalCommands: Commands {
    @FocusedValue(\.terminalModel) private var model

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Window") { AppActions.shared.openTerminalWindow() }.keyboardShortcut("n")
            Button("New Tab") { AppActions.shared.newTab() }.keyboardShortcut("t")
        }
        CommandGroup(replacing: .saveItem) {
            Button("Close Tab") { AppActions.shared.closeTab() }.keyboardShortcut("w")
            Button("Close Window") { AppActions.shared.closeWindow() }
                .keyboardShortcut("w", modifiers: [.command, .shift])
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
        CommandGroup(replacing: .pasteboard) {
            Button("Copy") {
                guard let text = model?.selectedText else { return }
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
            }
            .keyboardShortcut("c")
            .disabled(model?.hasSelection != true)
            Button("Paste") {
                if let text = NSPasteboard.general.string(forType: .string) { model?.send(.paste(text)) }
            }
            .keyboardShortcut("v")
            .disabled(model == nil)
            Button("Select All") { model?.selectAll() }
                .keyboardShortcut("a")
                .disabled(model == nil)
        }
    }
}
