import Observation

/// The keys of the commands in force: the table's (`AppCommand.table`), with those the file gives (`keys`) instead. A
/// command's keys are one key, or two pressed one after the other (`KeySequence`); a two-key command's first key is no
/// other command's key.
@MainActor @Observable package final class CommandKeys {
    package static let shared = CommandKeys()

    /// A command the file gives keys, or takes its key from (nil).
    private(set) var given: [AppCommand.ID: KeySequence?] = [:]

    package init() {}

    /// The keys `id` is run by now.
    package func sequence(for id: AppCommand.ID) -> KeySequence? {
        if let given = given[id] { return given }
        // A key the file gave another command, or the first of another's two, is that one's.
        guard let key = AppCommand[id].key,
            !given.values.contains(where: { $0?.first == key })
        else { return nil }
        return KeySequence(key)
    }

    /// The key `id` is run by when it is one key: what its menu item shows.
    package func key(for id: AppCommand.ID) -> KeyChord? {
        sequence(for: id)?.single
    }

    /// Whether `chord` starts some command's two keys: pressed, the next key is waited for.
    package func startsSequence(_ chord: KeyChord) -> Bool {
        AppCommand.ID.allCases.contains { id in
            guard let keys = sequence(for: id) else { return false }
            return keys.then != nil && keys.first == chord
        }
    }

    /// The command run by `first` then `then`, if any.
    package func command(first: KeyChord, then: KeyChord) -> AppCommand.ID? {
        AppCommand.ID.allCases.first { sequence(for: $0) == KeySequence(first, then: then) }
    }

    /// Whether the file gives `id` keys other than the table's.
    package func isGiven(_ id: AppCommand.ID) -> Bool {
        given[id] != nil
    }

    /// Takes the file's `keys`; what is not a command or not keys is said, by its path, and left out.
    @discardableResult
    package func take(_ keys: [String: String]) -> [(path: String, message: String)] {
        var issues: [(path: String, message: String)] = []
        var given: [AppCommand.ID: KeySequence?] = [:]
        for (name, text) in keys.sorted(by: { $0.key < $1.key }) {
            guard let id = AppCommand.ID(rawValue: name) else {
                issues.append(("keys.\(name)", "not a command"))
                continue
            }
            if text.isEmpty {
                given[id] = .some(nil)
            } else if let keys = KeySequence(text: text) {
                given[id] = keys
            } else {
                issues.append(
                    ("keys.\(name)", "expected one key with cmd or ctrl, or two apart, written as cmd+k or cmd+k cmd+t")
                )
            }
        }
        if given != self.given { self.given = given }
        return issues
    }

    /// The file's `keys` once `id` is run by `keys` (nil: by none): a command that had the same keys, whose one key is
    /// their first, or whose two start with this one key, loses them; a command back on its table key is left out of the
    /// file.
    package func giving(_ keys: KeySequence?, to id: AppCommand.ID, in file: [String: String]) -> [String: String] {
        var file = file
        if let keys {
            for other in AppCommand.ID.allCases where other != id {
                guard let theirs = sequence(for: other) else { continue }
                let clashes =
                    theirs == keys || (theirs.then == nil && theirs.first == keys.first)
                    || (keys.then == nil && theirs.first == keys.first)
                if clashes { file[other.rawValue] = "" }
            }
        }
        let table = AppCommand[id].key.map { KeySequence($0) }
        file[id.rawValue] = keys == table ? nil : keys?.text ?? ""
        return file
    }
}
