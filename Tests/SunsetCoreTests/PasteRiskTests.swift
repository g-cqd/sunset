import Testing

@testable import SunsetCore

/// White paper §9, threat model: a page's copied text run as commands. What a paste would do that the person may not see:
/// lines that run one after another without bracketed paste, control characters, characters that hide or reorder text. A
/// plain one-line paste, or several lines under bracketed paste, is not a risk.
@Suite("Paste: what would be risky")
struct PasteRiskTests {
    @Test func `plain text is not a risk; several lines under bracketed paste are not either`() {
        #expect(PasteRisk.of("git status", bracketed: false).isEmpty)
        #expect(PasteRisk.of("é ✓ 日本語 → tab\there", bracketed: false).isEmpty)
        #expect(PasteRisk.of("line one\nline two\n", bracketed: true).isEmpty)
    }

    @Test func `without bracketed paste, a line ending or several lines run as typed`() {
        #expect(PasteRisk.of("rm -rf build\n", bracketed: false) == [.runs(lines: 1)])
        #expect(PasteRisk.of("cd /\nrm -rf *", bracketed: false) == [.runs(lines: 1)])
        #expect(PasteRisk.of("a\r\nb\r\nc\n", bracketed: false) == [.runs(lines: 3)])
        #expect(PasteRisk.of("a\rb", bracketed: false) == [.runs(lines: 1)])
    }

    @Test func `control characters are a risk whatever the mode; tabs and line endings are not`() {
        #expect(PasteRisk.of("echo \u{1B}[31mred", bracketed: true) == [.controlCharacters])
        #expect(PasteRisk.of("x\u{03}y", bracketed: true) == [.controlCharacters])
        #expect(PasteRisk.of("x\u{7F}y", bracketed: true) == [.controlCharacters])
        #expect(
            PasteRisk.of("x\u{9B}31m", bracketed: true) == [.controlCharacters],
            "a C1 control: CSI in one character"
        )
    }

    @Test func `characters that hide or reorder text are a risk`() {
        #expect(PasteRisk.of("ls \u{202E}txt.exe", bracketed: true) == [.hiddenCharacters])
        #expect(PasteRisk.of("cu\u{200B}rl", bracketed: true) == [.hiddenCharacters])
        #expect(PasteRisk.of("a\u{2066}b\u{2069}", bracketed: true) == [.hiddenCharacters])
        #expect(PasteRisk.of("\u{FEFF}ls", bracketed: true) == [.hiddenCharacters])
        #expect(PasteRisk.of("x\u{E0041}", bracketed: true) == [.hiddenCharacters], "a tag character")
    }

    @Test func `every risk is said once, in order`() {
        #expect(
            PasteRisk.of("a\u{200B}\n\u{1B}x\nb", bracketed: false) == [
                .runs(lines: 2), .controlCharacters, .hiddenCharacters
            ]
        )
    }
}
