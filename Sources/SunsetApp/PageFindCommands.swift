import SunsetWeb
import SwiftUI

/// Find in the focused page (web step d): off while a terminal has the keyboard.
struct PageFindCommands: View {
    let page: WebContent?

    var body: some View {
        Menu("Find") {
            Button("Find\u{2026}") { page?.find.open() }.keyboardShortcut("f")
            Button("Find Next") { page?.find.search() }.keyboardShortcut("g")
                .disabled(page?.find.text.isEmpty != false)
            Button("Find Previous") { page?.find.search(backwards: true) }
                .keyboardShortcut("g", modifiers: [.command, .shift])
                .disabled(page?.find.text.isEmpty != false)
            Button("Use Selection for Find") { page?.find.useSelection() }.keyboardShortcut("e")
        }
        .disabled(page == nil)
    }
}
