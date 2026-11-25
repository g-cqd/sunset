import SunsetShell
import SunsetTerminalModel
import SunsetWeb
import SwiftUI

/// Find in the focused pane: routes Cmd-F / Cmd-G / Shift-Cmd-G / Cmd-E to either the focused web page or the focused
/// terminal's scrollback search (T-3 / roadmap 0026).
struct PageFindCommands: View {
    let page: WebContent?
    let focusedTerminal: TerminalModel?

    private var terminal: TerminalModel? {
        focusedTerminal
            ?? (TabRegistry.shared.tabs(for: TabRegistry.shared.actingWindow)?.selectedContent as? TerminalModel)
    }

    private var hasTarget: Bool {
        page != nil || terminal != nil
    }

    private var hasQuery: Bool {
        if let page { return !page.find.text.isEmpty }
        if let terminal { return !terminal.find.text.isEmpty }
        return false
    }

    var body: some View {
        Menu("Find") {
            Button("Find\u{2026}") {
                if let page {
                    page.find.open()
                } else {
                    terminal?.find.open()
                }
            }
            .keyboardShortcut("f")
            Button("Find Next") {
                if let page {
                    page.find.search()
                } else {
                    terminal?.find.step()
                }
            }
            .keyboardShortcut("g")
            .disabled(!hasQuery)
            Button("Find Previous") {
                if let page {
                    page.find.search(backwards: true)
                } else {
                    terminal?.find.step(backwards: true)
                }
            }
            .keyboardShortcut("g", modifiers: [.command, .shift])
            .disabled(!hasQuery)
            Button("Use Selection for Find") {
                if let page {
                    page.find.useSelection()
                } else {
                    terminal?.useSelectionForFind()
                }
            }
            .keyboardShortcut("e")
        }
        .disabled(!hasTarget)
    }
}
