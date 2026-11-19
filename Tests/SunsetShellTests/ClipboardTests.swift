import AppKit
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The owner's note n11: a copy goes through, or is blocked, and says which.
@MainActor
@Suite("Copying, and saying so") struct ClipboardTests {
    private func board() -> NSPasteboard {
        NSPasteboard(name: NSPasteboard.Name("sunset.tests.\(UUID().uuidString)"))
    }

    @Test func `a copy puts the text, and a link as a link, and says it is done`() {
        let board = board()
        #expect(
            Clipboard.copy("https://example.org/a", isLink: true, what: "Copied the address", to: board)
                == .done("Copied the address")
        )
        #expect(board.string(forType: .string) == "https://example.org/a")
        #expect(board.string(forType: .URL) == "https://example.org/a")
    }

    @Test func `nothing to copy is blocked, and the board is left as it was`() {
        let board = board()
        Clipboard.copy("kept", to: board)
        #expect(Clipboard.copy(nil, to: board) == .blocked("Nothing to copy"))
        #expect(Clipboard.copy("", to: board) == .blocked("Nothing to copy"))
        #expect(board.string(forType: .string) == "kept")
    }

    @Test func `a secret is marked so that clipboard managers leave it`() {
        let board = board()
        Clipboard.copy("code", concealed: true, to: board)
        #expect(board.types?.contains(NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")) == true)
    }

    @Test func `a button shows a check when done, a cross when blocked, and VoiceOver says why`() {
        #expect(ActionFeedback.done("Copied").symbol == "checkmark")
        #expect(ActionFeedback.blocked("No address").symbol == "xmark")
        #expect(ActionFeedback.blocked("No address").announcement == "No address")
        #expect(ActionFeedback.done("Copied").announcement == "Copied")
    }
}
