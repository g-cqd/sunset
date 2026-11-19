import Testing

@testable import SunsetCore

/// Task t116: what the paste warning says, and how it shows the text: control and hidden characters made visible, so the
/// person sees what would be sent.
@Suite("Paste: the warning's words")
struct PasteRiskExplanationTests {
    @Test func `the title names the first risk; each risk has its sentence`() {
        let risks: [PasteRisk] = [.runs(lines: 3), .controlCharacters, .hiddenCharacters]
        #expect(PasteRisk.title(of: risks) == "Paste text that runs 3 commands?")
        #expect(PasteRisk.title(of: [.runs(lines: 1)]) == "Paste text that runs a command?")
        #expect(PasteRisk.title(of: [.controlCharacters]) == "Paste text with control characters?")
        #expect(PasteRisk.title(of: [.hiddenCharacters]) == "Paste text with hidden characters?")
        #expect(risks.map(\.sentence).count == 3 && Set(risks.map(\.sentence)).count == 3)
    }

    @Test func `the preview shows what is sent: controls and hidden characters made visible, long text cut`() {
        #expect(PasteRisk.preview("echo \u{1B}[31m\u{200B}x\u{07}") == "echo ␛[31m⟨U+200B⟩x␇")
        #expect(PasteRisk.preview("a\tb") == "a\tb")
        let long = (1 ... 20).map { "line \($0)" }.joined(separator: "\n")
        let shown = PasteRisk.preview(long)
        #expect(shown.hasPrefix("line 1\nline 2") && shown.hasSuffix("…") && shown.split(separator: "\n").count <= 9)
    }
}
