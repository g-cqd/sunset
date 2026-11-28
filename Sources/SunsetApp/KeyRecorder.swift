import AppKit
import SunsetShellModel
import SwiftUI

/// A command's keys: clicked, it waits for a key pressed with Command or Control, then for a second (any key) or Return
/// to keep the first alone (`KeySequence`); Delete takes the keys away, Escape (or a click elsewhere) leaves them as they
/// were.
struct KeyRecorder: View {
    let keys: KeySequence?
    let record: (KeySequence?) -> Void
    @State private var recording = false
    /// The first key pressed, the second awaited.
    @State private var first: KeyChord?
    @State private var monitor: Any?

    private var shown: String {
        guard recording else { return keys?.symbols ?? "\u{2014}" }
        return first.map { "\($0.symbols) \u{2026}" } ?? "Press a key\u{2026}"
    }

    var body: some View {
        Button {
            recording ? stop() : start()
        } label: {
            Text(shown)
                .monospaced()
                .frame(minWidth: 90)
        }
        .buttonStyle(.bordered)
        .tint(recording ? .accentColor : nil)
        .accessibilityLabel(
            recording
                ? (first == nil ? "Press a key" : "Press a second key, or Return for one")
                : keys.map { "Keys \($0.symbols)" } ?? "No key"
        )
        .onDisappear(perform: stop)
    }

    private func start() {
        recording = true
        first = nil
        Self.takingKeys += 1
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .leftMouseDown]) { event in
            guard event.type == .keyDown else {
                stop()
                return event
            }
            take(event)
            return nil
        }
    }

    /// A key pressed while recording.
    private func take(_ event: NSEvent) {
        switch (event.keyCode, first) {
            case (53, _): stop()  // Escape
            case (51, nil), (117, nil):  // Delete, Forward Delete
                record(nil)
                stop()
            case (36, let first?), (76, let first?):  // Return, Enter: the first key alone
                record(KeySequence(first))
                stop()
            case (_, nil): first = Self.chord(of: event)
            case (_, let first?):
                guard let then = Self.chord(of: event, alone: true) else { return }
                record(KeySequence(first, then: then))
                stop()
        }
    }

    private func stop() {
        if recording { Self.takingKeys -= 1 }
        recording = false
        first = nil
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }

    /// How many recorders are taking a key now: two-key commands wait meanwhile.
    static var takingKeys = 0

    /// The key an event presses, when it has Command or Control (or any, `alone`: the second of two keys).
    static func chord(of event: NSEvent, alone: Bool = false) -> KeyChord? {
        let flags = event.modifierFlags
        let modifiers = Self.modifiers.reduce(into: KeyChord.Modifiers()) { held, pair in
            if flags.contains(pair.flag) { held.insert(pair.modifier) }
        }
        guard alone || !modifiers.isDisjoint(with: [.command, .control]) else { return nil }
        if let arrow = Self.arrows[event.keyCode] { return KeyChord(arrow, modifiers) }
        // The key's own character, not the one Shift makes of it: Shift-Command-] is "]" with Shift.
        guard let character = event.characters(byApplyingModifiers: [])?.lowercased().first else { return nil }
        return KeyChord(.character(character), modifiers)
    }

    private static let modifiers: [(flag: NSEvent.ModifierFlags, modifier: KeyChord.Modifiers)] = [
        (.command, .command), (.shift, .shift), (.option, .option), (.control, .control)
    ]

    /// The arrow keys, by key code.
    private static let arrows: [UInt16: KeyChord.Key] = [126: .up, 125: .down, 123: .left, 124: .right]
}
