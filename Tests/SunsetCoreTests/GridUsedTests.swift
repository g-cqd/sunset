import AemiTestKit
import Testing

@testable import SunsetCore

/// `Grid.used` is an upper bound: no cell at or past it is anything but empty. Blanking a row and saving it to the history rely on it, so every writer must
/// keep it, whatever the output.
@Suite("Grid: the used count of a row bounds its cells") struct GridUsedTests {
    private static let pieces: [String] = [
        "hello", " ", "x", "日本", "e\u{301}", "👍🏽", "\r\n", "\n", "\r", "\u{08}", "\t", "\u{1B}[41m", "\u{1B}[0m",
        "\u{1B}[7m",
        "\u{1B}[H", "\u{1B}[3;4H", "\u{1B}[2;1H", "\u{1B}[1;80H", "\u{1B}[A", "\u{1B}[3C", "\u{1B}[K", "\u{1B}[1K",
        "\u{1B}[2K", "\u{1B}[J", "\u{1B}[1J",
        "\u{1B}[2J", "\u{1B}[2@", "\u{1B}[2P", "\u{1B}[3X", "\u{1B}[L", "\u{1B}[M", "\u{1B}[S", "\u{1B}[T",
        "\u{1B}[?1049h", "\u{1B}[?1049l",
        "\u{1B}[2;4r", "\u{1B}[r", "\u{1B}[4h", "\u{1B}[4l", "\u{1B}#8", "\u{1B}[?7l", "\u{1B}[?7h"
    ]

    private func check(_ grid: Grid, _ context: @autoclosure () -> String) -> Bool {
        for physical in 0 ..< grid.rows {
            let start = physical * grid.columns
            for column in grid.used(physical: physical) ..< grid.columns where grid.cells[start + column].raw != 0 {
                Issue.record(
                    "physical row \(physical) column \(column) is not empty past used \(grid.used(physical: physical)): \(context())"
                )
                return false
            }
        }
        return true
    }

    @Test func `no output leaves a cell past the used count of its row`() {
        var random = SeededRNG(seed: 5)
        for round in 0 ..< 300 {
            var terminal = Terminal(columns: 4 + random.below(16), rows: 2 + random.below(6), scrollbackLimit: 50)
            var history = ""
            for _ in 0 ..< 30 {
                var chunk = ""
                for _ in 0 ..< 1 + random.below(5) { chunk += Self.pieces[random.below(Self.pieces.count)] }
                history += chunk
                terminal.feed(chunk)
                if random.below(20) == 0 { terminal.resize(columns: 4 + random.below(16), rows: 2 + random.below(6)) }
                guard check(terminal.screen.grid, "round \(round) after \(history.debugDescription)"),
                    check(terminal.screen.other, "alternate, round \(round) after \(history.debugDescription)")
                else { return }
            }
        }
    }

    @Test func `the history keeps what a line held`() {
        var terminal = Terminal(columns: 10, rows: 2, scrollbackLimit: 100)
        terminal.feed("a\r\n\u{1B}[41m\u{1B}[K\u{1B}[0mcolour\r\nlonger line!\r\nx\r\ny")
        #expect(terminal.screen.scrollbackText(line: 0) == "a")
        #expect(terminal.screen.scrollbackText(line: 2) == "longer lin")
        // The erase in a background colour made the whole row cells of their own: kept, as before.
        let line = terminal.screen.viewportRow(0, scrolledBack: terminal.screen.scrollbackCount - 1)
        #expect(line.count == 10)
    }
}
