import SunsetCore
import SunsetTestSupport
import Testing

@testable import SunsetHost

/// A cell's size in pixels reaches the program as image tools look for it (ADR-0117): asked of the terminal (CSI 16 t). (The
/// window size's pixels, `TIOCGWINSZ`, are set with it; `stty` does not show them.)
@Suite("A cell's size in pixels, told to the program", .serialized)
struct CellPixelSizeTests {
    @Test func `a resize with a cell's size: the program asks the terminal, and is told it`() async throws {
        let session = try TerminalSession(
            [
                "/bin/sh", "-c",
                "stty raw -echo; read -r x; printf '\\033[16t'; dd bs=1 count=10 2>/dev/null | od -An -tx1"
            ],
            columns: 80,
            rows: 24
        )
        await session.start()
        await session.resize(columns: 80, rows: 24, cellWidth: 10, cellHeight: 20)
        await session.send(Array("\n".utf8))
        // ESC [ 6 ; 2 0 ; 1 0 t
        let answer = "1b5b363b32303b313074"
        let told = await RealWait.until(within: .seconds(10)) {
            let screen = await session.takeSnapshot()
            return (0 ..< screen.rows).contains { screen.text(row: $0).filter { !$0.isWhitespace }.contains(answer) }
        }
        #expect(told)
    }
}
