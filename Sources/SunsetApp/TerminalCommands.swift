import AppKit
import SwiftUI

/// The menu: paste into the focused terminal.
struct TerminalCommands: Commands {
    @FocusedValue(\.terminalModel) private var model

    var body: some Commands {
        CommandGroup(replacing: .pasteboard) {
            Button("Paste") {
                if let text = NSPasteboard.general.string(forType: .string) { model?.send(.paste(text)) }
            }
            .keyboardShortcut("v")
            .disabled(model == nil)
        }
    }
}
