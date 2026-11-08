import Testing

@testable import SunsetHost

@Suite("Concentric corner radius") struct ConcentricRadiusTests {
    @Test func `an inner corner keeps the window's centre: radius minus the gap`() {
        #expect(ConcentricRadius.inner(outer: 16, inset: 8) == 8)
        #expect(ConcentricRadius.inner(outer: 16, inset: 3) == 13)
    }

    @Test func `a gap wider than the radius leaves a square corner, never a negative one`() {
        #expect(ConcentricRadius.inner(outer: 16, inset: 20) == 0)
        #expect(ConcentricRadius.inner(outer: 0, inset: 4) == 0)
    }

    @Test func `nonsense gives a square corner`() {
        #expect(ConcentricRadius.inner(outer: .nan, inset: 4) == 0)
        #expect(ConcentricRadius.inner(outer: 16, inset: -1) == 16, "a negative gap is none")
    }
}
