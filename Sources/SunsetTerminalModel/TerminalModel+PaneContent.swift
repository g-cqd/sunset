package import Foundation
package import SunsetCore
import SunsetHost
package import SunsetPane
package import SunsetShellModel

/// The terminal as the content of a pane.
extension TerminalModel: PaneContent {
    package var detail: String? {
        directory
    }

    /// The program in front of the shell, so that a tab is found by what runs in it.
    package var searchTerms: [String] {
        foregroundCommand.map { [$0] } ?? []
    }

    /// The folder the program is in (with its first letter), or the command in front.
    package var glyph: PaneGlyph {
        .tab(TabGlyph.make(directory: directory, command: foregroundCommand, home: NSHomeDirectory()))
    }

    /// A command is in front of the shell, as last looked at (debounced after the screen changes).
    package var runsCommand: Bool {
        isRunning && foregroundCommand != nil
    }

    /// A command in front of the shell would be killed. Asked now: the debounced look at the foreground would be late.
    package var closeWarning: String? {
        guard isRunning, let command = refreshForegroundNow() else { return nil }
        return "\(command) is running"
    }

    /// Captures the terminal's current scrollback and primary screen into a `ScreenSnapshot` (roadmap 0024 S-1).
    package func captureSnapshot(at now: Date) -> ScreenSnapshot? {
        guard let screen = session?.screenCopy() ?? lastScreen else { return nil }
        let snap = screen.snapshot(savedAt: Int64(now.timeIntervalSince1970))
        return snap.lines.isEmpty ? nil : snap
    }

    /// The directory the shell reported (plus its snapshot ID so saved scrollback can be replayed across quit/close),
    /// or the one it was (or is to be) started in: a tab restored and never shown has reported nothing yet.
    package var descriptor: PaneDescriptor {
        var desc = PaneDescriptor.terminal(directory: directory ?? startDirectory)
        desc.state["snapshot"] = snapshotID.uuidString
        return desc
    }

    package func setState(focused: Bool, visible: Bool) {
        paneStateChanged(focused: focused, visible: visible)
    }
}
