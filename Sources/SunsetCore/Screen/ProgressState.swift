/// A progress report from the program (OSC 9;4, ConEmu): what a window's dock icon or title bar can show.
public enum ProgressState: Sendable, Equatable {
    case hidden
    case normal(percent: Int)
    case error(percent: Int)
    case indeterminate
    case paused(percent: Int)
}
