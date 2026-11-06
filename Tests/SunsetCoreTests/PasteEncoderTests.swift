import Testing

@testable import SunsetCore

@Suite("Paste") struct PasteEncoderTests {
    @Test func `bracketed paste wraps the text`() {
        #expect(PasteEncoder.encode("hello\nworld", bracketed: true) == bytes("\u{1B}[200~hello\nworld\u{1B}[201~"))
    }

    @Test func `a paste cannot close its own brackets`() {
        #expect(PasteEncoder.encode("a\u{1B}[201~b", bracketed: true) == bytes("\u{1B}[200~ab\u{1B}[201~"))
        // Removing one marker must not leave another behind.
        #expect(PasteEncoder.encode("a\u{1B}[201\u{1B}[201~~b", bracketed: true) == bytes("\u{1B}[200~ab\u{1B}[201~"))
    }

    @Test func `without brackets line feeds become carriage returns`() {
        #expect(PasteEncoder.encode("a\nb\r\nc", bracketed: false) == bytes("a\rb\rc"))
    }
}
