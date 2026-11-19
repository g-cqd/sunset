import Foundation
import SunsetTestSupport
import Testing

/// The owner's note n11 (2026-11-18): "a visual cue that the link is copied when clicking on the copy link in the address
/// bar, same goes for all buttons … UX/UI and haptic feedback … as to when a click goes through or is blocked". Every copy
/// goes through `Clipboard.copy`, which says what it did.
@Suite("Every copy says it copied") struct ClipboardGateTests {
    /// The clipboard itself; a terminal's copy of its selection (Cmd-C, as every terminal, silent) and a program's write
    /// through OSC 52 (its own policy, white paper §9; the model asks, the app writes: `TerminalModel+App.swift`), which are
    /// not clicks.
    static let exempt: Set<String> = [
        "Clipboard.swift", "TerminalNSView+Pasteboard.swift", "TerminalModel+App.swift"
    ]

    @Test func `no code writes to the pasteboard but the clipboard's`() {
        var writes: [String] = []
        for file in RepositoryFiles.swiftFiles(in: ["Sources"]) where !Self.exempt.contains(file.name) {
            for (index, line) in file.text.components(separatedBy: "\n").enumerated()
            where line.contains(".setString(") || line.contains("clearContents()") {
                writes.append("\(file.name):\(index + 1)")
            }
        }
        #expect(writes.isEmpty, "\(writes)")
    }
}
