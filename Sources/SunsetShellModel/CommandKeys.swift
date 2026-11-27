import Observation

/// The keys of the commands in force: the table's (`AppCommand.table`), with those the file gives (`keys`) instead.
@MainActor @Observable package final class CommandKeys {
    package static let shared = CommandKeys()

    /// A command the file gives a key, or takes its key from (nil).
    private(set) var given: [AppCommand.ID: KeyChord?] = [:]

    package init() {}

    /// The key `id` is run by now.
    package func key(for id: AppCommand.ID) -> KeyChord? {
        if let given = given[id] { return given }
        // A key the file gave another command is that one's.
        guard let key = AppCommand[id].key, !given.values.contains(key) else { return nil }
        return key
    }

    /// Whether the file gives `id` a key other than the table's.
    package func isGiven(_ id: AppCommand.ID) -> Bool {
        given[id] != nil
    }

    /// Takes the file's `keys`; what is not a command or not a key is said, by its path, and left out.
    @discardableResult
    package func take(_ keys: [String: String]) -> [(path: String, message: String)] {
        var issues: [(path: String, message: String)] = []
        var given: [AppCommand.ID: KeyChord?] = [:]
        for (name, text) in keys.sorted(by: { $0.key < $1.key }) {
            guard let id = AppCommand.ID(rawValue: name) else {
                issues.append(("keys.\(name)", "not a command"))
                continue
            }
            if text.isEmpty {
                given[id] = .some(nil)
            } else if let chord = KeyChord(text: text) {
                given[id] = chord
            } else {
                issues.append(("keys.\(name)", "expected a key with cmd or ctrl, written as cmd+shift+d"))
            }
        }
        if given != self.given { self.given = given }
        return issues
    }

    /// The file's `keys` once `id` is run by `chord` (nil: by none): the command that had it loses it; a command back on
    /// its table key is left out of the file.
    package func giving(_ chord: KeyChord?, to id: AppCommand.ID, in keys: [String: String]) -> [String: String] {
        var keys = keys
        if let chord {
            for other in AppCommand.ID.allCases where other != id && key(for: other) == chord {
                keys[other.rawValue] = ""
            }
        }
        keys[id.rawValue] = chord == AppCommand[id].key ? nil : chord?.text ?? ""
        return keys
    }
}
