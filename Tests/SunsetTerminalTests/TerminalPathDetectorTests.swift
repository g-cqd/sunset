import Foundation
import Testing

@testable import SunsetTerminalModel

/// Tests terminal plain-text file path & `:line[:column]` detection (M-h / t211).
@Suite("Terminal file path detection") struct TerminalPathDetectorTests {
    @Test func `detects relative, absolute, and tilde paths with optional line and column`() throws {
        let existing: Set<String> = [
            "/workspace/project/docs/README.md",
            "/workspace/project/Sources/Main.swift",
            "/tmp/notes.md",
            "/home/demo/todo.md"
        ]
        let cwd = "/workspace/project"
        let home = "/home/demo"

        let rel = try #require(
            TerminalPathDetector.detect(
                in: "error in Sources/Main.swift:42:12 (failed)",
                at: 14,
                workingDirectory: cwd,
                homeDirectory: home,
                fileExists: existing.contains
            )
        )
        #expect(rel.url.path == "/workspace/project/Sources/Main.swift")
        #expect(rel.line == 42 && rel.column == 12)

        let abs = try #require(
            TerminalPathDetector.detect(
                in: "See (/tmp/notes.md:7), please",
                at: 8,
                workingDirectory: cwd,
                homeDirectory: home,
                fileExists: existing.contains
            )
        )
        #expect(abs.url.path == "/tmp/notes.md")
        #expect(abs.line == 7 && abs.column == nil)

        let tilde = try #require(
            TerminalPathDetector.detect(
                in: "open ~/todo.md now",
                at: 7,
                workingDirectory: cwd,
                homeDirectory: home,
                fileExists: existing.contains
            )
        )
        #expect(tilde.url.path == "/home/demo/todo.md")
        #expect(tilde.line == nil && tilde.column == nil)
    }

    @Test func `ignores URLs, non-existent files, and whitespace`() {
        #expect(
            TerminalPathDetector.detect(
                in: "https://example.com/README.md",
                at: 10,
                workingDirectory: "/tmp",
                fileExists: { _ in true }
            ) == nil
        )
        #expect(
            TerminalPathDetector.detect(
                in: "missing/file.md",
                at: 3,
                workingDirectory: "/tmp",
                fileExists: { _ in false }
            ) == nil
        )
        #expect(
            TerminalPathDetector.detect(
                in: "hello world",
                at: 5,
                workingDirectory: "/tmp",
                fileExists: { _ in true }
            ) == nil
        )
    }
}
