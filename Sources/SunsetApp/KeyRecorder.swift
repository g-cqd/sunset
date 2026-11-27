import AppKit
import SunsetShellModel
import SwiftUI

/// A command's key: clicked, it waits for the next key pressed with Command or Control and takes it; Delete takes the
/// key away, Escape (or a click elsewhere) leaves it as it was.
struct KeyRecorder: View {
    let key: KeyChord?
    let record: (KeyChord?) -> Void
    @State private var recording = false
    @State private var monitor: Any?

    var body: some View {
        Button {
            recording ? stop() : start()
        } label: {
            Text(recording ? "Press a key\u{2026}" : key?.symbols ?? "\u{2014}")
                .monospaced()
                .frame(minWidth: 90)
        }
        .buttonStyle(.bordered)
        .tint(recording ? .accentColor : nil)
        .accessibilityLabel(recording ? "Press a key" : key.map { "Key \($0.symbols)" } ?? "No key")
        .onDisappear(perform: stop)
    }

    private func start() {
        recording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .leftMouseDown]) { event in
            guard event.type == .keyDown else {
                stop()
                return event
            }
            switch event.keyCode {
                case 53: stop()  // Escape
                case 51, 117:  // Delete, Forward Delete
                    record(nil)
                    stop()
                default:
                    guard let chord = Self.chord(of: event) else { return nil }
                    record(chord)
                    stop()
            }
            return nil
        }
    }

    private func stop() {
        recording = false
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }

    /// The key an event presses, when it has Command or Control.
    static func chord(of event: NSEvent) -> KeyChord? {
        var modifiers: KeyChord.Modifiers = []
        let flags = event.modifierFlags
        if flags.contains(.command) { modifiers.insert(.command) }
        if flags.contains(.shift) { modifiers.insert(.shift) }
        if flags.contains(.option) { modifiers.insert(.option) }
        if flags.contains(.control) { modifiers.insert(.control) }
        guard !modifiers.isDisjoint(with: [.command, .control]) else { return nil }
        let key: KeyChord.Key
        switch event.keyCode {
            case 126: key = .up
            case 125: key = .down
            case 123: key = .left
            case 124: key = .right
            default:
                // The key's own character, not the one Shift makes of it: Shift-Command-] is "]" with Shift.
                guard let character = event.characters(byApplyingModifiers: [])?.lowercased().first else { return nil }
                key = .character(character)
        }
        return KeyChord(key, modifiers)
    }
}
