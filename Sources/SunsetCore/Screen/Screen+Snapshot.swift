import Foundation

/// Capturing and replaying terminal screen & scrollback snapshots (roadmap 0024 S-1 / S-2, t190 / t213).
extension Screen {
    /// Captures the primary screen's non-empty lines and up to `maximumLines` of scrollback into a `ScreenSnapshot`.
    /// When the terminal is currently in the alternate screen (e.g. vim/htop), only the primary scrollback is captured
    /// (alternate-screen interactive apps cannot be resumed).
    public func snapshot(
        savedAt: Int64,
        maximumLines: Int = ScreenSnapshot.defaultMaximumLines
    ) -> ScreenSnapshot {
        guard maximumLines > 0 else {
            return ScreenSnapshot(columns: columns, rows: rows, savedAt: savedAt, lines: [])
        }
        // Only capture live screen rows on the primary screen, trimming trailing completely blank rows below the last
        // non-empty row (or cursor row).
        let liveEnd: Int
        if isAlternate {
            liveEnd = 0
        } else {
            var last = -1
            for r in stride(from: rows - 1, through: 0, by: -1)
            where !trimmedLineText(absoluteLine: scrollback.count + r).isEmpty {
                last = r
                break
            }
            liveEnd = last + 1
        }
        let total = scrollback.count + liveEnd
        guard total > 0 else {
            return ScreenSnapshot(columns: columns, rows: rows, savedAt: savedAt, lines: [])
        }
        let start = max(0, total - maximumLines)
        var captured: [ScreenSnapshot.Line] = []
        captured.reserveCapacity(total - start)
        for absLine in start ..< total {
            let wrapped = isAbsoluteWrapped(line: absLine) && absLine + 1 < total
            let text = trimmedLineText(absoluteLine: absLine, keepTrailingSpaces: wrapped)
            captured.append(ScreenSnapshot.Line(text: text, wrapped: wrapped))
        }
        return ScreenSnapshot(columns: columns, rows: rows, savedAt: savedAt, lines: captured)
    }

    private func trimmedLineText(absoluteLine line: Int, keepTrailingSpaces: Bool = false) -> String {
        var scalars = String.UnicodeScalarView()
        forEachAbsoluteCell(on: line) { cell, _, _ in
            appendText(of: cell, to: &scalars)
        }
        if !keepTrailingSpaces {
            while scalars.last == " " { scalars.removeLast() }
        }
        return String(scalars)
    }
}
