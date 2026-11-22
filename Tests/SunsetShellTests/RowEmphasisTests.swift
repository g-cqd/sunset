import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// With several tabs selected, the shown one must still look selected, not only shown.
@Suite("A row's emphasis") struct RowEmphasisTests {
    @Test func `the shown row among several selected is drawn as selected and shown`() {
        #expect(RowEmphasis.of(shown: true, marked: true) == .markedShown)
        #expect(RowEmphasis.of(shown: true, marked: true).isAccent)
        #expect(!RowEmphasis.of(shown: true, marked: false).isAccent)
        #expect(RowEmphasis.of(shown: false, marked: true) == .marked)
    }
}
