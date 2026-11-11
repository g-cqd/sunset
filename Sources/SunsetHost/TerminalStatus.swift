public import SunsetCore

/// What a tab shows of a terminal without drawing it: the title, the directory and the progress the program reported. Read cheaply (no copy of the cells), so
/// that a tab that is not shown still updates its label (n48).
public struct TerminalStatus: Sendable, Equatable {
    public let title: String
    public let workingDirectory: WorkingDirectory?
    public let progress: ProgressState
    /// The shell has drawn its prompt and waits for a command (its last mark, with shell integration, is a prompt or the start of what is typed).
    public let atPrompt: Bool
    /// The shell marks its prompts at all (shell integration is on).
    public let marksPrompts: Bool

    public init(_ screen: Screen) {
        title = screen.title
        workingDirectory = screen.workingDirectory
        progress = screen.progress
        let last = screen.promptMarks.last?.kind
        atPrompt = last == .promptStart || last == .commandStart
        marksPrompts = !screen.promptMarks.isEmpty
    }
}
