public import SunsetCore

/// What a tab shows of a terminal without drawing it: the title, the directory and the progress the program reported. Read cheaply (no copy of the cells), so
/// that a tab that is not shown still updates its label (n48).
public struct TerminalStatus: Sendable, Equatable {
    public let title: String
    public let workingDirectory: WorkingDirectory?
    public let progress: ProgressState

    public init(_ screen: Screen) {
        title = screen.title
        workingDirectory = screen.workingDirectory
        progress = screen.progress
    }
}
