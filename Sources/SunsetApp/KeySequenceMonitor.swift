import AppKit
import SunsetShell
import SunsetShellModel

/// Two-key commands (`KeySequence`): the first key of one is taken before the menus and the panes see it, the second runs
/// the command; Escape, a click, or a key no command's two end with stops waiting.
@MainActor enum KeySequenceMonitor {
    private static var monitor: Any?

    /// Starts watching the keys, once.
    static func start() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .leftMouseDown, .rightMouseDown]) { event in
            handle(event) ? nil : event
        }
    }

    /// Whether `event` was taken by a two-key command.
    private static func handle(_ event: NSEvent) -> Bool {
        let pending = PendingKeys.shared
        guard event.type == .keyDown else {
            pending.first = nil
            return false
        }
        // Only for the app's windows, not a sheet or a recorder taking keys.
        guard pending.first != nil || KeyRecorder.takingKeys == 0 else { return false }
        let waiting = pending.first != nil
        guard let chord = KeyRecorder.chord(of: event, alone: waiting) else {
            if waiting { pending.first = nil }
            return waiting
        }
        switch pending.press(chord, escape: event.keyCode == 53, keys: CommandKeys.shared) {
            case .pass: return false
            case .wait, .cancel: return true
            case .run(let id):
                if AppCommandRunner.isEnabled(id) { AppCommandRunner.run(id) } else { NSSound.beep() }
                return true
        }
    }
}
