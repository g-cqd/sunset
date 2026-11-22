import AppKit
import SunsetRuntime
import SunsetTestSupport
import Testing

@testable import SunsetShell

/// A secret copied (a password, a code, a recovery code) leaves the clipboard on its own after a while, as password
/// managers do; unless something else was copied since, which stays. A pasteboard of the test's own, never the clipboard.
@MainActor @Suite("Secrets copied leave the clipboard")
struct ClipboardExpiryTests {
    @Test func `a secret goes after the delay; text copied since stays; a plain copy never goes`() async throws {
        let time = TestTime()
        let board = NSPasteboard(name: NSPasteboard.Name("sunset-test-\(UUID().uuidString)"))
        defer { board.releaseGlobally() }
        let expiry = ClipboardExpiry(after: .seconds(90), runtime: time.runtime)
        var mark = time.mark()
        Clipboard.copy("hunter2", concealed: true, to: board, expiry: expiry)
        try await time.release(after: .seconds(90), since: mark)
        #expect(board.string(forType: .string) == nil, "the secret is gone")
        mark = time.mark()
        Clipboard.copy("hunter2", concealed: true, to: board, expiry: expiry)
        try await time.waited(since: mark)
        board.clearContents()
        board.setString("something else", forType: .string)
        time.advance(.seconds(90))
        try await time.settle()
        #expect(board.string(forType: .string) == "something else", "what was copied since stays")
        Clipboard.copy("a link", to: board, expiry: expiry)
        time.advance(.seconds(600))
        try await time.settle()
        #expect(board.string(forType: .string) == "a link", "a plain copy stays")
    }
}
