import SunsetCore
import SunsetTestSupport
import Testing

@testable import SunsetHost

/// Task t116: what the terminal's side of the PTY says about pastes and passwords. A paste's risks follow the program's
/// bracketed-paste mode; a program reading a password (echo off in line mode, as `readpassphrase` sets it, then its
/// prompt) is seen from the master side (probed: diary 2026-11-19-13), and an editor (echo off in raw mode) is not.
@Suite("Session: pastes and passwords", .serialized)
struct SessionSecretsTests {
    private func started(_ script: String) async throws -> TerminalSession {
        let session = try TerminalSession(["/bin/sh", "-c", script], columns: 80, rows: 24)
        await session.start()
        return session
    }

    @Test func `a paste's risks follow the program's bracketed-paste mode`() async throws {
        let plain = try await started("printf 'ready'; sleep 5")
        #expect(await RealWait.until(within: .seconds(10)) { await plain.takeSnapshot().text(row: 0) == "ready" })
        #expect(await plain.pasteRisks("a\nb") == [.runs(lines: 1)])
        let bracketed = try await started("printf '\\033[?2004hready'; sleep 5")
        #expect(await RealWait.until(within: .seconds(10)) { await bracketed.takeSnapshot().text(row: 0) == "ready" })
        #expect(await bracketed.pasteRisks("a\nb").isEmpty)
        #expect(await bracketed.pasteRisks("a\u{1B}b") == [.controlCharacters])
    }

    @Test func `a password prompt is seen while it is up, not before or after`() async throws {
        let session = try await started(
            "printf 'start'; sleep 1; stty -echo; printf 'Password:'; sleep 1.5; stty echo; printf ' done'; sleep 5"
        )
        #expect(await RealWait.until(within: .seconds(10)) { await session.takeSnapshot().text(row: 0) == "start" })
        #expect(!session.asksSecret())
        #expect(await RealWait.until(within: .seconds(10)) { session.asksSecret() })
        #expect(await RealWait.until(within: .seconds(10)) { !session.asksSecret() })
    }

    @Test func `echo off in raw mode (an editor, a shell's line editor) is not a password prompt`() async throws {
        let session = try await started("stty -echo -icanon; printf 'raw'; sleep 5")
        #expect(await RealWait.until(within: .seconds(10)) { await session.takeSnapshot().text(row: 0) == "raw" })
        #expect(!session.asksSecret())
    }
}
