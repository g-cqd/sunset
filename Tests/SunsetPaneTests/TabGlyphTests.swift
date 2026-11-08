import Testing

@testable import SunsetPane

@Suite("Tab glyph") struct TabGlyphTests {
    private func glyph(_ directory: String?, command: String? = nil) -> TabGlyph {
        TabGlyph.make(directory: directory, command: command, home: "/Users/me")
    }

    @Test func `a directory gives a folder with the first letter of its name, in capitals`() {
        #expect(glyph("/Users/me/Projects/sunset") == TabGlyph(kind: .folder, letter: "S"))
        #expect(glyph("/tmp") == TabGlyph(kind: .folder, letter: "T"))
        #expect(
            glyph("/Users/me/Projects/sunset/") == TabGlyph(kind: .folder, letter: "S"),
            "a trailing slash is not a name"
        )
    }

    @Test func `a hidden folder is named by its first letter or digit, not by the dot`() {
        #expect(glyph("/Users/me/.config") == TabGlyph(kind: .folder, letter: "C"))
        #expect(glyph("/Users/me/_build") == TabGlyph(kind: .folder, letter: "B"))
        #expect(glyph("/x/2024-notes") == TabGlyph(kind: .folder, letter: "2"))
    }

    @Test
    func `the home folder and the root have marks of their own, and a name with no letter keeps its first character`() {
        #expect(glyph("/Users/me") == TabGlyph(kind: .folder, letter: "~"))
        #expect(glyph("/") == TabGlyph(kind: .folder, letter: "/"))
        #expect(glyph("/x/🚀launch") == TabGlyph(kind: .folder, letter: "🚀"))
        #expect(glyph("/x/éclair") == TabGlyph(kind: .folder, letter: "É"))
    }

    @Test func `no directory yet is a plain folder`() {
        #expect(glyph(nil) == TabGlyph(kind: .folder, letter: nil))
        #expect(glyph("") == TabGlyph(kind: .folder, letter: nil))
    }

    @Test func `a program running in the foreground gives the command mark, whatever the directory`() {
        #expect(glyph("/tmp", command: "vim") == TabGlyph(kind: .command, letter: nil))
        #expect(glyph(nil, command: "ssh").kind == .command)
    }

    @Test func `the login shell itself is not a command`() {
        for shell in ["zsh", "-zsh", "bash", "fish", "sh", "-fish", "nu", "tcsh", "dash", "ksh", "elvish", "xonsh"] {
            #expect(glyph("/tmp", command: shell).kind == .folder, "\(shell)")
        }
        #expect(glyph("/tmp", command: "").kind == .folder)
    }
}
