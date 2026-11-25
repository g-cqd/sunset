import SunsetCore
import Testing

/// Terminal screen & scrollback snapshotting and replay (`Screen.snapshot`, `ScreenSnapshot.replayBytes`,
/// roadmap 0024 S-1 / S-2, t190 / t213).
@Suite("Terminal screen & scrollback snapshots")
struct ScreenSnapshotTests {
    @Test func `captures primary scrollback and non-empty screen lines and replays with a divider`() {
        var terminal = Terminal(columns: 12, rows: 4, scrollbackLimit: 100)
        terminal.feed("line-one\r\nwrapped_line_overflow\r\nlast-line")
        let snap = terminal.screen.snapshot(savedAt: 1_700_000_000)

        #expect(snap.version == ScreenSnapshot.currentVersion)
        #expect(snap.columns == 12 && snap.rows == 4)
        #expect(snap.lines.map(\.text) == ["line-one", "wrapped_line", "_overflow", "last-line"])
        #expect(snap.lines[1].wrapped == true)
        #expect(snap.lines[2].wrapped == false)

        // Replaying into a fresh wider terminal preserves the joined wrapped line and appends the dim divider.
        var restored = Terminal(columns: 40, rows: 10, scrollbackLimit: 100)
        restored.feed(snap.replayBytes().span)
        let rendered = restored.screen.search(SearchQuery(text: "wrapped_line_overflow"))
        #expect(rendered.matches.count == 1)
        let divider = restored.screen.search(SearchQuery(text: "restored session"))
        #expect(divider.matches.count == 1)
    }

    @Test func `respects maximumLines and skips alternate-screen live rows`() {
        var terminal = Terminal(columns: 20, rows: 3, scrollbackLimit: 100)
        terminal.feed("row0\r\nrow1\r\nrow2\r\nrow3\r\nrow4")
        let capped = terminal.screen.snapshot(savedAt: 1, maximumLines: 2)
        #expect(capped.lines.map(\.text) == ["row3", "row4"])

        // Enter alternate screen (e.g. vim) and draw something; snapshot must not capture alternate screen content.
        terminal.feed("\u{1B}[?1049hALT-ONLY")
        let altSnap = terminal.screen.snapshot(savedAt: 2)
        #expect(!altSnap.lines.contains(where: { $0.text.contains("ALT-ONLY") }))
    }
}
