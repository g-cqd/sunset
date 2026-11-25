/// Serialisable snapshot of a terminal's scrollback history and primary screen lines for session restore across quit
/// or window close (roadmap 0024 S-1 / S-2, t190 / t213).
///
/// Stores logical lines (joined across soft wraps) as styled text runs so restored output adapts cleanly to any new
/// window width, with bounded size (`maximumLines`, `maximumBytes`) so hostile/huge terminal buffers never blow up
/// disk or launch latency.
public struct ScreenSnapshot: Codable, Equatable, Sendable {
    public static let currentVersion = 1
    /// Maximum lines captured from the bottom of scrollback + primary screen (newest lines kept).
    public static let defaultMaximumLines = 10_000
    /// Hard byte cap on a single encoded snapshot (8 MiB) before dropping oldest lines.
    public static let maximumEncodedBytes = 8 << 20

    public struct Line: Codable, Equatable, Sendable {
        public let text: String
        public let wrapped: Bool

        public init(text: String, wrapped: Bool = false) {
            self.text = text
            self.wrapped = wrapped
        }
    }

    public let version: Int
    public let columns: Int
    public let rows: Int
    public let savedAt: Int64
    public let lines: [Line]

    public init(version: Int = currentVersion, columns: Int, rows: Int, savedAt: Int64, lines: [Line]) {
        self.version = version
        self.columns = columns
        self.rows = rows
        self.savedAt = savedAt
        self.lines = lines
    }

    /// Formats the snapshot into a terminal-ready byte stream ending with a subtle dim divider rule so the person can
    /// immediately tell restored output from the fresh shell prompt below it (S-2 / t213).
    public func replayBytes(marker: String = "─── restored session ───") -> [UInt8] {
        guard let lastLine = lines.last else { return [] }
        var out = ""
        out.reserveCapacity(lines.count * 48)
        for line in lines {
            out.append(line.text)
            if !line.wrapped {
                out.append("\r\n")
            }
        }
        if lastLine.wrapped {
            out.append("\r\n")
        }
        // Dim separator line (SGR 2 … SGR 0) before the new shell draws its prompt.
        out.append("\u{1B}[2m\(marker)\u{1B}[0m\r\n")
        return Array(out.utf8)
    }
}
