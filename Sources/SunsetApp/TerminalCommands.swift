import AppKit
import SwiftUI

/// The menu: copy the selection, paste, select all.
struct TerminalCommands: Commands {
    @FocusedValue(\.terminalModel) private var model

    var body: some Commands {
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
