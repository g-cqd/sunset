import Observation

/// The first of two keys pressed, the second awaited (`KeySequence`): shown in the window until the second comes.
@MainActor @Observable package final class PendingKeys {
    package static let shared = PendingKeys()

    /// The first key pressed; nil when no second is awaited.
    package var first: KeyChord?

    package init() {}

    /// What the second key does, given the first is `first`: run a command, wait no more (Escape, or a key that starts no
    /// command's two), or nothing to do with these keys.
    package enum Outcome: Equatable {
        case run(AppCommand.ID)
        case cancel
        case wait
        case pass
    }

    /// What `chord` does now: pressed with nothing awaited, it starts waiting when it starts a command's two keys.
    package func press(_ chord: KeyChord, escape: Bool, keys: CommandKeys) -> Outcome {
        guard let first else {
            guard keys.startsSequence(chord) else { return .pass }
            self.first = chord
            return .wait
        }
        self.first = nil
        if escape { return .cancel }
        return keys.command(first: first, then: chord).map(Outcome.run) ?? .cancel
    }
}
