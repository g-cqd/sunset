import Testing

@testable import SunsetHost

@Suite("Font zoom") struct FontZoomTests {
    @Test func `the size is the configured one plus the zoom`() {
        #expect(FontZoom(offset: 0).size(base: 14) == 14)
        #expect(FontZoom(offset: 3).size(base: 14) == 17)
        #expect(FontZoom(offset: -2).size(base: 14) == 12)
    }

    @Test func `the size stays in the range the configuration accepts`() {
        #expect(FontZoom(offset: -50).size(base: 14) == 4)
        #expect(FontZoom(offset: 500).size(base: 14) == 200)
    }

    @Test func `stepping changes the offset by the step, and stops where the size stops`() {
        var zoom = FontZoom(offset: 0)
        zoom.step(by: 1, base: 14)
        zoom.step(by: 1, base: 14)
        #expect(zoom.offset == 2)
        zoom.step(by: -5, base: 14)
        #expect(zoom.offset == -3)
        var small = FontZoom(offset: 0)
        for _ in 0 ..< 30 { small.step(by: -1, base: 6) }
        #expect(small.size(base: 6) == 4 && small.offset == -2, "no offset is stored that has no effect")
        var big = FontZoom(offset: 0)
        for _ in 0 ..< 300 { big.step(by: 1, base: 190) }
        #expect(big.size(base: 190) == 200 && big.offset == 10)
    }

    @Test func `a zoom that was reset, or never used, is off`() {
        var zoom = FontZoom(offset: 4)
        #expect(!zoom.isReset)
        zoom.reset()
        #expect(zoom.isReset && zoom.size(base: 14) == 14)
    }
}
