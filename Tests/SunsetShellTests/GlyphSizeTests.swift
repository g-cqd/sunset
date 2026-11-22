import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// "our synthesized icons for folders with initial appear bigger than the sf symbol used for folder on other tabs". A
/// terminal's folder, its command mark and a symbol chosen for a tab are drawn at one size.
@Suite("A tab's picture: one size for every symbol")
@MainActor
struct GlyphSizeTests {
    @Test func `the folder with its initial is the size of any other tab symbol`() {
        #expect(TabGlyphView.symbolSize == PaneIconView.symbolSize)
        #expect(TabGlyphView.initialSize < TabGlyphView.symbolSize / 2, "the letter fits in the folder's body")
    }
}
