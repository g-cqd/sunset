import CoreText
import Foundation
import Testing

@testable import SunsetRenderMac

/// Tests T-7 / t182 terminal font styling: per-style font overrides (bold, italic, boldItalic), ordered fallback
/// cascade lists, and OpenType variable-font axis parsing & application.
@Suite("Font styling: per-style fonts, fallbacks, variable axes") struct FontStylingTests {
    @Test func `variable axis parser accepts valid 4-char ASCII tags and ignores malformed entries`() {
        let parsed = FontVariationAxis.parseList("wght=550, opsz=12.5, bad=1, wght=nan, nope, wdth=90")
        #expect(
            parsed == [FontVariationAxis("wght", 550), FontVariationAxis("opsz", 12.5), FontVariationAxis("wdth", 90)]
        )
        #expect(FontVariationAxis("wght", 500).fourCharCode == 0x7767_6874)
        #expect(FontVariationAxis("ab", 1).fourCharCode == nil)
    }

    @Test func `per-style overrides replace bold and italic faces when installed, and fall back cleanly when absent`() {
        let appearance = FontAppearance(
            boldName: "Courier",
            italicName: "NotARealFontFamilyXYZ",
            boldItalicName: "Courier-BoldOblique",
            fallbackNames: ["Hiragino Sans", "Apple Symbols"],
            variations: [FontVariationAxis("wght", 600)]
        )
        let source = CoreTextGlyphSource(fontName: "Menlo", size: 14, appearance: appearance)
        let regularFamily = CTFontCopyFamilyName(source.regular) as String
        let boldFamily = CTFontCopyFamilyName(source.bold) as String
        let italicFamily = CTFontCopyFamilyName(source.italic) as String
        #expect(regularFamily == "Menlo")
        #expect(boldFamily == "Courier")
        #expect(italicFamily == "Menlo")

        // Verify fallback cascade list attribute was attached to the CTFont descriptor.
        let descriptor = CTFontCopyFontDescriptor(source.regular)
        let cascade = CTFontDescriptorCopyAttribute(descriptor, kCTFontCascadeListAttribute) as? [CTFontDescriptor]
        #expect(cascade?.count == 2)

        // Verify variation axis dictionary was attached to the CTFont descriptor.
        let variations = CTFontDescriptorCopyAttribute(descriptor, kCTFontVariationAttribute) as? [NSNumber: NSNumber]
        #expect(variations?[NSNumber(value: 0x7767_6874 as UInt32)]?.doubleValue == 600)

        // Rasterising regular and bold glyphs succeeds without trapping.
        #expect(source.glyph(for: "A", bold: false, italic: false, columns: 1, metrics: source.metrics) != nil)
        #expect(source.glyph(for: "A", bold: true, italic: false, columns: 1, metrics: source.metrics) != nil)
    }
}
