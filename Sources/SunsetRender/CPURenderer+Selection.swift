internal import SunsetCore

extension CPURenderer {
    /// The rows of the window a selection covers, or nil.
    func selectionRows(of selection: Selection?, in frame: Frame) -> ClosedRange<Int>? {
        guard let selection else { return nil }
        let first = max(selection.start.line - frame.firstLine, 0)
        let last = min(selection.end.line - frame.firstLine, frame.screen.rows - 1)
        return first <= last ? first ... last : nil
    }
}
