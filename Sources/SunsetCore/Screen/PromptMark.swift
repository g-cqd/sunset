/// A semantic mark from the shell (OSC 133, the FinalTerm protocol): where a prompt starts, where the command's text starts, where its output starts and
/// where it ended. Lines are *stable* numbers (lines scrolled out of the history so far plus the line's index), so a mark keeps pointing at its line while the
/// history rolls; `Screen.absoluteLine(ofStable:)` says where that line is now, or nil when it left the history.
public struct PromptMark: Sendable, Equatable {
    public enum Kind: Sendable, Equatable {
        case promptStart, commandStart, outputStart, commandEnd
    }

    public var kind: Kind
    public var stableLine: Int
    /// For `commandEnd`: the exit status (0-255), when the shell sent one.
    public var exitStatus: Int?

    public init(kind: Kind, stableLine: Int, exitStatus: Int? = nil) {
        self.kind = kind
        self.stableLine = stableLine
        self.exitStatus = exitStatus
    }
}
