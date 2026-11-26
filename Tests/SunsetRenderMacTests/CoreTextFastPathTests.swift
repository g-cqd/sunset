import AemiTestKit
import CoreText
import Foundation
import SunsetRender
import Testing

@testable import SunsetRenderMac

/// The ASCII fast path (t241) draws a run cell by cell, without shaping, when every byte of it is in the style's safe
/// set (`SubstitutionReach`); that is only right if shaping such a run would change nothing. Checked here against shaping itself
/// (`runIsPlain`, which shapes) on every monospaced font this Mac has, in all four styles, with ligatures on and off,
/// over seeded random runs built only from the bytes the fast path calls safe — not over a list chosen by hand.
@Suite("ASCII fast path: safe bytes never shape") struct CoreTextFastPathTests {
    /// The monospaced families installed here (a machine with fewer fonts checks fewer).
    static let families: [String] = {
        let collection = CTFontCollectionCreateFromAvailableFonts(nil)
        let descriptors = (CTFontCollectionCreateMatchingFontDescriptors(collection) as? [CTFontDescriptor]) ?? []
        var found = Set<String>()
        for descriptor in descriptors {
            let traits = CTFontDescriptorCopyAttribute(descriptor, kCTFontTraitsAttribute) as? [String: Any]
            let symbolic = (traits?[kCTFontSymbolicTrait as String] as? NSNumber)?.uint32Value ?? 0
            guard symbolic & CTFontSymbolicTraits.traitMonoSpace.rawValue != 0,
                let family = CTFontDescriptorCopyAttribute(descriptor, kCTFontFamilyNameAttribute) as? String
            else { continue }
            found.insert(family)
        }
        return found.sorted()
    }()

    @Test func `there are fonts to check`() {
        #expect(Self.families.contains("Menlo"), "\(Self.families)")
    }

    /// A font's substitution tables let go only the bytes a rule could change in a run of safe bytes: Menlo's AAT
    /// `morx` ligates `fi` and `fl`, so `f` shapes and every other byte is drawn cell by cell; Andale Mono has no table.
    /// Both ship with macOS.
    @Test(arguments: [true, false])
    func `a font's substitution tables let go only the bytes their rules use`(ligatures: Bool) {
        let menlo = CoreTextGlyphSource(fontName: "Menlo", size: 28, ligatures: ligatures)
        let andale = CoreTextGlyphSource(fontName: "Andale Mono", size: 28, ligatures: ligatures)
        let bytes = UInt8(0x21) ... UInt8(0x7E)
        let shaped = bytes.filter { !menlo.asciiRunByteIsPlain($0, bold: false, italic: false) }
        #expect(String(decoding: shaped, as: UTF8.self) == "f")
        #expect(bytes.filter { !menlo.asciiRunByteIsPlain($0, bold: true, italic: false) } == shaped)
        for (bold, italic) in [(false, false), (true, false), (false, true), (true, true)] {
            #expect(bytes.allSatisfy { andale.asciiRunByteIsPlain($0, bold: bold, italic: italic) })
        }
    }

    @Test(arguments: families, [true, false])
    func `random runs of safe bytes shape to their characters' own glyphs`(family: String, ligatures: Bool) {
        let source = CoreTextGlyphSource(fontName: family, size: 28, ligatures: ligatures)
        let metrics = source.metrics
        var rng = SeededRNG(seed: family.utf8.reduce(UInt64(0x7241)) { $0 &* 31 &+ UInt64($1) })
        for (bold, italic) in [(false, false), (true, false), (false, true), (true, true)] {
            let safe = (UInt8(0x21) ... UInt8(0x7E))
                .filter {
                    source.asciiRunByteIsPlain($0, bold: bold, italic: italic)
                }
            guard safe.count > 1 else { continue }
            for sample in 0 ..< 2_000 {
                let length = 2 + Int(rng.next() % 11)
                let run = String(
                    decoding: (0 ..< length).map { _ in safe[Int(rng.next() % UInt64(safe.count))] },
                    as: UTF8.self
                )
                let plain = source.runIsPlain(run, bold: bold, italic: italic, metrics: metrics)
                #expect(plain, "\(family) ligatures=\(ligatures) bold=\(bold) italic=\(italic): \(run) shapes")
                guard plain else { return }
                if sample.isMultiple(of: 200) {
                    let whole = source.glyph(forRun: run, bold: bold, italic: italic, cells: length, metrics: metrics)
                    let side = CoreTextPlainRunTests().sideBySide(run, source, bold: bold, italic: italic)
                    #expect(whole?.coverage == side, "\(family): \(run) differs from side by side")
                }
            }
        }
    }
}
