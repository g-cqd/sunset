import Foundation
import Testing

@testable import SunsetPane

@Suite("A symbol icon's colour") struct IconColorTests {
    @Test func `a colour reads and writes as #RRGGBB, and nothing else is a colour`() {
        #expect(IconColor(hex: "#1A2b3C") == IconColor(red: 0x1A, green: 0x2B, blue: 0x3C))
        #expect(IconColor(hex: "0a0b0c")?.hex == "#0A0B0C")
        #expect(IconColor(hex: "#12345") == nil && IconColor(hex: "#GG0000") == nil && IconColor(hex: "") == nil)
    }

    @Test func `a coloured symbol is saved with its colour; a bad colour reads as none`() throws {
        let icon = PaneIcon.symbol("bolt", color: IconColor(red: 255, green: 0, blue: 128))
        let data = try JSONEncoder().encode(icon)
        #expect(String(decoding: data, as: UTF8.self).contains("#FF0080"))
        #expect(try JSONDecoder().decode(PaneIcon.self, from: data) == icon)
        let bad = Data(#"{"symbol":"bolt","color":"red"}"#.utf8)
        #expect(try JSONDecoder().decode(PaneIcon.self, from: bad) == .symbol("bolt"))
        #expect(PaneIcon.emoji("🚀").colored(IconColor(red: 1, green: 2, blue: 3)) == .emoji("🚀"))
    }
}
