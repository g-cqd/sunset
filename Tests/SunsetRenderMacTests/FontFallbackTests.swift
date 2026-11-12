import CoreText
import Testing

@testable import SunsetRenderMac

/// A missing name is not asked of CoreText here: doing so while the other tests make fonts hung the whole test process (2026-11-12). The app's
/// path with a missing font is checked by launching it.
@Suite("A missing font falls back to Menlo") struct FontFallbackTests {
    @Test func `an installed font is used`() {
        #expect(CTFontCopyFamilyName(FontFallback.font(named: "Menlo", size: 12)) as String == "Menlo")
    }

    @Test func `a font is the one asked for when one of its names is the name; Helvetica for JetBrains Mono is not`() {
        let menlo = ["Menlo", "Menlo Regular", "Menlo-Regular"]
        #expect(FontFallback.isMatch("Menlo", names: menlo) && FontFallback.isMatch("menlo-regular", names: menlo))
        #expect(!FontFallback.isMatch("JetBrains Mono", names: ["Helvetica", "Helvetica", "Helvetica"]))
        #expect(
            FontFallback.isMatch(
                "JetBrains Mono",
                names: ["JetBrains Mono", "JetBrains Mono Regular", "JetBrainsMono-Regular"]
            )
        )
    }
}
