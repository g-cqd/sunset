import AppKit
import SunsetMetrics
import SwiftUI
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The button at the window's bottom corner, concentric with the window's corner. It was 6.5 pt from the window's side
/// (the margin, the tabs' inset, half a hairline) and 4.5 from its bottom, with the 5 pt corner every sidebar button
/// has. Now the bar 2 pt higher, so both distances are 6.5, and only the corner at the window's corner takes the radius
/// that shares its centre, 16 - 6.5 = 9.5; the three others keep `layout.sidebarButtonRadius`.
@MainActor @Suite("The sidebar button at the window's corner") struct SidebarCornerTests {
    func docked(window: Double = 16) -> SidebarButtons {
        SidebarButtons(layout: LayoutMetrics(), margin: 4, panelRadius: nil, windowRadius: window)
    }

    @Test func `docked, the bar is as far from the window's bottom as its buttons are from the window's side`() {
        let buttons = docked()
        #expect(buttons.bottom == buttons.margin + buttons.gap)
        #expect(buttons.bottom == 6.5)
    }

    @Test func `the corner at the window's corner shares its centre, the others keep the setting`() {
        let buttons = docked()
        #expect(buttons.metrics.radius == LayoutMetrics().sidebarButtonRadius)
        #expect(buttons.metrics.windowCorner == 16 - 6.5)
        #expect(docked(window: 20).metrics.windowCorner == 13.5)
    }

    @Test func `it is never sharper than the button's own corner`() {
        #expect(docked(window: 10).metrics.windowCorner == LayoutMetrics().sidebarButtonRadius)
        #expect(docked(window: 0).metrics.windowCorner == LayoutMetrics().sidebarButtonRadius)
    }

    @Test func `floating, the buttons are already concentric with the panel, all four corners`() {
        let buttons = SidebarButtons(layout: LayoutMetrics().floatingTabs, margin: 4, panelRadius: 12, windowRadius: 16)
        #expect(buttons.metrics.windowCorner == buttons.metrics.radius)
        #expect(buttons.bottom == buttons.gap)
    }

    @Test func `the rows leave the bar the room they left it, 2 pt higher`() {
        let buttons = docked()
        #expect(buttons.barRoom == buttons.metrics.size.height + buttons.layout.tabSpacing + 2)
    }

    /// The downloads' button stacked above the Library's glyph makes the bar two rows high: the rows leave it one more
    /// button and its spacing, and the bar is that high.
    @Test func `a bar two buttons high: the rows leave it a button and a spacing more`() {
        let buttons = docked()
        let row = buttons.metrics.size.height + buttons.layout.tabSpacing
        #expect(buttons.barRoom(rows: 1) == buttons.barRoom)
        #expect(buttons.barRoom(rows: 2) == buttons.barRoom + row)
        #expect(buttons.barHeight(rows: 2) == 2 * buttons.metrics.size.height + buttons.layout.tabSpacing)
    }

    /// How far in along the diagonal the first drawn pixel is from each corner of a pressed button drawn at 8 px a point:
    /// top left, top right, bottom left, bottom right.
    func cuts(_ corner: SidebarButtonCorner?) throws -> [Int] {
        let face = SidebarIconButtonFace(label: Color.clear, pressed: true, metrics: docked().metrics)
            .environment(\.sidebarButtonCorner, corner)
            .environment(\.layoutDirection, .leftToRight)
        let renderer = ImageRenderer(content: face)
        renderer.scale = 8
        let image = NSBitmapImageRep(cgImage: try #require(renderer.cgImage))
        let wide = image.pixelsWide
        let high = image.pixelsHigh
        func cut(_ fromRight: Bool, _ fromBottom: Bool) -> Int {
            for step in 0 ..< min(wide, high) / 2 {
                let x = fromRight ? wide - 1 - step : step
                let y = fromBottom ? high - 1 - step : step
                if (image.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.02 { return step }
            }
            return -1
        }
        return [cut(false, false), cut(true, false), cut(false, true), cut(true, true)]
    }

    @Test func `drawn: no corner named, four alike`() throws {
        let cuts = try cuts(nil)
        #expect(Set(cuts).count == 1 && cuts[0] > 0, "\(cuts)")
    }

    @Test func `drawn: the named corner is the rounder one, by 9.5 to 5, and the three others are as before`() throws {
        let plain = try cuts(nil)
        for (corner, index) in [(SidebarButtonCorner.bottomLeading, 2), (.bottomTrailing, 3)] {
            let cuts = try cuts(corner)
            for other in 0 ..< 4 where other != index { #expect(cuts[other] == plain[other], "\(corner): \(cuts)") }
            // A circle of radius r is r(1 - 1/sqrt 2) in along the diagonal: 0.29 x (9.5 - 5) x 8 px = 10 px more.
            #expect(
                cuts[index] - plain[index] >= 7 && cuts[index] - plain[index] <= 14,
                "\(corner): \(cuts) for \(plain)"
            )
        }
    }
}
