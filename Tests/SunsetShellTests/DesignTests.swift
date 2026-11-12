import SunsetMetrics
import Testing

@testable import SunsetShell

@Suite("Design tokens") struct DesignTests {
    @Test func `the spacing scale is on a 2 pt base, and a value between steps moves up`() {
        #expect(Design.Space.scale == [2, 4, 6, 8, 12, 16, 24])
        #expect(Design.Space.scale.allSatisfy { $0.truncatingRemainder(dividingBy: 2) == 0 })
        #expect(
            Design.Space.step(atLeast: 3) == 4 && Design.Space.step(atLeast: 10) == 12
                && Design.Space.step(atLeast: 14) == 16
        )
        #expect(Design.Space.step(atLeast: 20) == 24 && Design.Space.step(atLeast: 6) == 6)
    }

    @Test func `a surface's corner is concentric with its leaves; the leaf is the tabs' radius`() {
        let layout = LayoutMetrics()
        #expect(Design.Radius.leaf(layout) == layout.tabRadius && Design.Radius.surface(layout) == 12)
        #expect(Design.Radius.container(holding: 6, inset: 6) - 6 == ConcentricRadius.inner(outer: 12, inset: 6) - 0)
        #expect(Design.Size.bar == 36)
    }

    @Test func `the accent: sunset is the tint, the system's when there is none`() {
        #expect(Design.Accent.resolve("system", tint: [1, 2, 3]) == .system)
        #expect(Design.Accent.resolve("sunset", tint: nil) == .system)
        #expect(Design.Accent.resolve("sunset", tint: [255, 128, 0]) == .color(red: 255, green: 128, blue: 0))
        #expect(Design.Accent.resolve("neutral", tint: nil) == .neutral)
    }
}
