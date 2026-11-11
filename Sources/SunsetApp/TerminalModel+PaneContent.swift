import Foundation
import SunsetPane
import SunsetShell
import SwiftUI

/// The terminal as the content of a pane.
extension TerminalModel: PaneContent {
    var detail: String? { directory }

    /// The program in front of the shell, so that a tab is found by what runs in it.
    var searchTerms: [String] { foregroundCommand.map { [$0] } ?? [] }

    /// The folder the program is in (with its first letter), or the command in front.
    var glyph: PaneGlyph {
        .tab(TabGlyph.make(directory: directory, command: foregroundCommand, home: NSHomeDirectory()))
    }

    /// A command in front of the shell would be killed. Asked now: the debounced look at the foreground would be late.
    var closeWarning: String? {
        guard isRunning, let command = refreshForegroundNow() else { return nil }
        return "\(command) is running"
    }

    /// The directory the shell reported, or the one it was (or is to be) started in: a tab restored and never shown has reported nothing yet.
    var descriptor: PaneDescriptor { .terminal(directory: directory ?? startDirectory) }

    func setState(focused: Bool, visible: Bool) { paneStateChanged(focused: focused, visible: visible) }

    func makeView(_ context: PaneViewContext) -> AnyView {
        AnyView(
            TerminalRepresentable(
                model: self,
                optionAsMeta: context.optionAsMeta,
                translucent: context.translucent,
                focused: context.focused
            )
        )
    }
}
