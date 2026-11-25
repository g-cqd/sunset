import SunsetCore
import Testing

/// Terminal scrollback & live-screen search (`Screen.search`, T-3 / roadmap 0026): plain-text literal matching,
/// case-insensitive vs case-sensitive, RE2 regular expressions, invalid regex handling, wrapped logical lines, wide
/// CJK/emoji cells, and result limit truncation.
@Suite("Terminal scrollback search")
struct ScreenSearchTests {
    @Test func `finds plain text across scrollback and live screen with case sensitivity options`() {
        var terminal = Terminal(columns: 40, rows: 4, scrollbackLimit: 100)
        terminal.feed("alpha one\r\nBETA two\r\nalpha three\r\nfour\r\nfive\r\nALPHA six")

        let screen = terminal.screen
        #expect(screen.scrollbackCount >= 2)

        let insensitive = screen.search(SearchQuery(text: "alpha", isRegex: false, matchCase: false))
        #expect(insensitive.error == nil)
        #expect(insensitive.matches.count == 3)
        #expect(insensitive.matches.map { screen.text(of: $0.selection) } == ["alpha", "alpha", "ALPHA"])

        let sensitive = screen.search(SearchQuery(text: "alpha", isRegex: false, matchCase: true))
        #expect(sensitive.matches.count == 2)
        #expect(sensitive.matches.map { screen.text(of: $0.selection) } == ["alpha", "alpha"])

        // Plain-text mode escapes regex metacharacters (`[a-z]+`, `.`, `(`) literally.
        terminal.feed("\r\nfoo[0].bar")
        let literal = terminal.screen.search(SearchQuery(text: "[0].", isRegex: false, matchCase: true))
        #expect(literal.matches.count == 1)
        #expect(terminal.screen.text(of: literal.matches[0].selection) == "[0].")
    }

    @Test func `supports RE2 regex across wrapped lines and wide characters, and reports invalid patterns`() throws {
        var terminal = Terminal(columns: 10, rows: 4, scrollbackLimit: 100)
        // "hello_world_42" wraps across rows 0 (cols 0..9) and 1 (cols 0..3).
        terminal.feed("hello_world_42\r\n")
        // Wide CJK characters occupy 2 columns each: "日本" -> cols 0..3, "ERR-99" -> cols 4..9.
        terminal.feed("日本ERR-99")

        let screen = terminal.screen
        let wrapped = screen.search(SearchQuery(text: #"world_\d+"#, isRegex: true, matchCase: true))
        #expect(wrapped.error == nil)
        #expect(wrapped.matches.count == 1)
        let first = try #require(wrapped.matches.first)
        #expect(first.start.line == 0 && first.end.line == 1)
        #expect(screen.text(of: first.selection) == "world_42")

        let afterWide = screen.search(SearchQuery(text: #"ERR-\d+"#, isRegex: true, matchCase: true))
        #expect(afterWide.matches.count == 1)
        let wideHit = try #require(afterWide.matches.first)
        #expect(wideHit.start.column == 4 && wideHit.end.column == 9)
        #expect(screen.text(of: wideHit.selection) == "ERR-99")

        let cjk = screen.search(SearchQuery(text: "日本", isRegex: false, matchCase: true))
        #expect(cjk.matches.count == 1)
        let cjkHit = try #require(cjk.matches.first)
        #expect(cjkHit.start.column == 0 && cjkHit.end.column == 3)

        // Invalid regex returns an error string without trapping.
        let invalid = screen.search(SearchQuery(text: "(unclosed", isRegex: true))
        #expect(invalid.matches.isEmpty)
        #expect(invalid.error != nil)

        // Result cap truncates cleanly.
        let capped = screen.search(SearchQuery(text: "[a-z]", isRegex: true), limit: 3)
        #expect(capped.matches.count == 3)
        #expect(capped.truncated)
    }
}
