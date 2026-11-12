import SunsetMetrics
import SwiftUI
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
        #expect(Design.Size.bar == 38 && Design.Size.bar - Design.Size.field == 2 * Design.Space.s)
    }

    @Test func `the accent: sunset is the tint, the system's when there is none or it is too dark or too light`() {
        #expect(Design.Accent.resolve("system", tint: [1, 2, 3]) == .system)
        #expect(Design.Accent.resolve("sunset", tint: nil) == .system)
        #expect(Design.Accent.resolve("sunset", tint: [255, 128, 0]) == .color(red: 255, green: 128, blue: 0))
        #expect(Design.Accent.resolve("sunset", tint: [0, 0, 0]) == .system, "the owner's black tint")
        #expect(Design.Accent.resolve("sunset", tint: [250, 250, 250]) == .system)
        #expect(Design.Accent.resolve("neutral", tint: nil) == .neutral)
    }

    @Test func `ink on the accent: dark on a light accent, light on a dark one; neutral is light grey on dark`() {
        #expect(Design.Accent.luminance([255, 255, 255]) > 0.99 && Design.Accent.luminance([0, 0, 0]) == 0)
        #expect(
            Design.Accent.neutral.style(dark: true).ink == .black
                && Design.Accent.neutral.style(dark: false).ink == .white
        )
        #expect(Design.Accent.color(red: 255, green: 220, blue: 80).style(dark: true).ink == .black)
        #expect(Design.Accent.color(red: 30, green: 60, blue: 200).style(dark: true).ink == .white)
    }

    @Test func `a floating fill is the tint's colour, at least 0.85 opaque`() {
        #expect(SurfaceStyle(kind: .fill, tint: [0, 0, 0, 0.5]).fillComponents == [0, 0, 0, 0.85])
        #expect(SurfaceStyle(kind: .fill, tint: [1, 0.5, 0, 0.95]).fillComponents == [1, 0.5, 0, 0.95])
        #expect(SurfaceStyle(kind: .fill).fillComponents == [0, 0, 0, 0.85])
    }
}
