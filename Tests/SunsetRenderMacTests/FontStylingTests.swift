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
        // A family named for bold is that family's bold face, and a missing one leaves Menlo's own italic.
        #expect(CTFontGetSymbolicTraits(source.bold).contains(.traitBold))
        #expect(CTFontCopyPostScriptName(source.italic) as String == "Menlo-Italic")
        #expect(CTFontCopyPostScriptName(source.boldItalic) as String == "Courier-BoldOblique")

        // Verify fallback cascade list attribute was attached to the CTFont descriptor.
        let descriptor = CTFontCopyFontDescriptor(source.regular)
        let cascade = CTFontDescriptorCopyAttribute(descriptor, kCTFontCascadeListAttribute) as? [CTFontDescriptor]
        #expect(cascade?.count == 2)

        // The variation axes are the regular face's (as Ghostty's font-variation): bold keeps its own weight.
        let variations = CTFontDescriptorCopyAttribute(descriptor, kCTFontVariationAttribute) as? [NSNumber: NSNumber]
        #expect(variations?[NSNumber(value: 0x7767_6874 as UInt32)]?.doubleValue == 600)
        let boldDescriptor = CTFontCopyFontDescriptor(source.bold)
        #expect(CTFontDescriptorCopyAttribute(boldDescriptor, kCTFontVariationAttribute) == nil)

        // Rasterising regular and bold glyphs succeeds without trapping.
        #expect(source.glyph(for: "A", bold: false, italic: false, columns: 1, metrics: source.metrics) != nil)
        #expect(source.glyph(for: "A", bold: true, italic: false, columns: 1, metrics: source.metrics) != nil)
    }

    /// A weight set for the regular face of a variable font does not reach bold, which stays bold (measured with the
    /// variable monospaced fonts installed here; none skips the check).
    @Test(arguments: ["JetBrains Mono", "Geist Mono", "Google Sans Code"])
    func `a weight for the regular face leaves bold bold`(family: String) throws {
        let probe = CTFontCreateWithName(family as CFString, 14, nil)
        try #require(CTFontCopyFamilyName(probe) as String == family, "\(family) is not installed")
        let wght = NSNumber(value: 0x7767_6874 as UInt32)
        let source = CoreTextGlyphSource(
            fontName: family,
            size: 14,
            appearance: FontAppearance(variations: [FontVariationAxis("wght", 500)])
        )
        let regular = (CTFontCopyVariation(source.regular) as? [NSNumber: NSNumber])?[wght]?.doubleValue
        let bold = (CTFontCopyVariation(source.bold) as? [NSNumber: NSNumber])?[wght]?.doubleValue
        #expect(regular == 500)
        #expect((bold ?? 0) >= 700, "bold is \(bold ?? 0)")
    }

    /// A family named for a style is that family's face in the style; a face named exactly is that face; a name that is
    /// not installed leaves the main font's own face for the style (CoreText would otherwise hand back Helvetica).
    @Test func `a style override names a family or a face, and a missing one falls back to the main font`() {
        let base = CTFontCreateWithName("Menlo" as CFString, 14, nil)
        func styled(_ name: String?, _ traits: CTFontSymbolicTraits) -> String {
            CTFontCopyPostScriptName(
                CoreTextGlyphSource.styleFont(override: name, traits: traits, from: base, size: 14)
            )
                as String
        }
        #expect(styled("Courier", .traitBold) == "Courier-Bold")
        #expect(styled("Courier", [.traitBold, .traitItalic]) == "Courier-BoldOblique")
        #expect(styled("Courier-Bold", .traitBold) == "Courier-Bold")
        #expect(styled("Courier Bold", .traitBold) == "Courier-Bold")
        #expect(styled("NotARealFontFamilyXYZ", .traitBold) == "Menlo-Bold")
        #expect(styled("Helvetica Neue Nope", .traitItalic) == "Menlo-Italic")
        #expect(styled("  ", .traitBold) == "Menlo-Bold")
        #expect(styled(nil, [.traitBold, .traitItalic]) == "Menlo-BoldItalic")
    }
}
