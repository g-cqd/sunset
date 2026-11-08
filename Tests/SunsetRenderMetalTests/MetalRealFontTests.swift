import SunsetCore
import SunsetRender
import Testing

@testable import SunsetRenderMetal

/// Real anti-aliased glyphs from CoreText, ligatures and wide characters included.
@Suite("Metal renderer with a real font", .serialized) struct MetalRealFontTests {
    private let esc = "\u{1B}"

    @Test func `text in the system monospaced font is exact`() throws {
        var rig = try #require(MetalRig(columns: 40, rows: 8, font: "Menlo"), "a Metal device")
        try rig.frame(
            "The quick brown fox jumps over the lazy dog 0123456789\r\n\(esc)[1mBold\(esc)[0m \(esc)[3mitalic\(esc)[0m \(esc)[31;1mcolour\(esc)[0m\r\nfn main() { let x = a != b && c >= d; } // ->"
        )
        let difference = rig.differences()
        #expect(difference.count == 0, "\(difference.count) pixels differ, by up to \(difference.largest)")
    }

    @Test func `wide characters, emoji and combining marks are exact`() throws {
        var rig = try #require(MetalRig(columns: 30, rows: 4, font: "Menlo"), "a Metal device")
        try rig.frame("日本語 テキスト 한글 🚀 e\u{301} 👨‍👩‍👧\r\nمرحبا שלום")
        let difference = rig.differences()
        #expect(difference.count == 0, "\(difference.count) pixels differ, by up to \(difference.largest)")
    }

    @Test func `scrolling a screenful of text keeps the two in step`() throws {
        var rig = try #require(MetalRig(columns: 40, rows: 6, font: "Menlo"), "a Metal device")
        for line in 1 ... 30 { try rig.frame("line \(line) of the flood \(esc)[3\(line % 8)mcoloured\(esc)[0m\r\n") }
        #expect(rig.differences().count == 0)
    }
}
