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
        var buffer: [UInt8] = []
        buffer.reserveCapacity(columns * 2)
        var scalars = String.UnicodeScalarView()
        scalars.reserveCapacity(4)
        for absLine in start ..< total {
            let wrapped = isAbsoluteWrapped(line: absLine) && absLine + 1 < total
            let text = trimmedLineText(
                absoluteLine: absLine,
                keepTrailingSpaces: wrapped,
                buffer: &buffer,
                scalars: &scalars
            )
            captured.append(ScreenSnapshot.Line(text: text, wrapped: wrapped))
        }
        return ScreenSnapshot(columns: columns, rows: rows, savedAt: savedAt, lines: captured)
    }

    private func trimmedLineText(absoluteLine line: Int, keepTrailingSpaces: Bool = false) -> String {
        var buffer: [UInt8] = []
        var scalars = String.UnicodeScalarView()
        return trimmedLineText(
            absoluteLine: line,
            keepTrailingSpaces: keepTrailingSpaces,
            buffer: &buffer,
            scalars: &scalars
        )
    }

    private func trimmedLineText(
        absoluteLine line: Int,
        keepTrailingSpaces: Bool,
        buffer: inout [UInt8],
        scalars: inout String.UnicodeScalarView
    ) -> String {
        buffer.removeAll(keepingCapacity: true)
        forEachAbsoluteCell(on: line) { cell, _, _ in
            appendCellUTF8(cell, to: &buffer, scalars: &scalars)
        }
        if !keepTrailingSpaces {
            while buffer.last == 0x20 { buffer.removeLast() }
        }
        return String(decoding: buffer, as: UTF8.self)
    }
}
