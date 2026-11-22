import CoreGraphics
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

@Suite("Where a tab's preview goes") struct PreviewPlacementTests {
    private let area = CGRect(x: 200, y: 0, width: 800, height: 600)
    private let size = CGSize(width: 292, height: 200)

    @Test func `beside a row of a sidebar on the left, level with it, on the left`() {
        let row = CGRect(x: 10, y: 300, width: 180, height: 30)
        let origin = PreviewPlacement.origin(size: size, row: row, area: area, sidebarOnRight: false)
        #expect(origin.x == 12 && origin.y == 315 - 100)
    }

    @Test func `beside a row of a sidebar on the right, on the right`() {
        let left = CGRect(x: 0, y: 0, width: 800, height: 600)
        let row = CGRect(x: 810, y: 100, width: 180, height: 30)
        let origin = PreviewPlacement.origin(size: size, row: row, area: left, sidebarOnRight: true)
        #expect(origin.x == 800 - 292 - 12 && origin.y == 15)
    }

    @Test func `beside a floating sidebar's row over the area, not under the panel`() {
        let left = PreviewPlacement.origin(
            size: size,
            row: CGRect(x: 210, y: 300, width: 180, height: 30),
            area: area,
            sidebarOnRight: false
        )
        #expect(left.x == 390 - 200 + 12 && left.y == 315 - 100)
        let right = PreviewPlacement.origin(
            size: size,
            row: CGRect(x: 800, y: 300, width: 180, height: 30),
            area: area,
            sidebarOnRight: true
        )
        #expect(abs(right.x - 296) < 0.001, "\(right.x)")
    }

    /// With the sidebar floating, the previews of the Pinned grid's tiles, of indented rows and of groups showed beneath
    /// the sidebar: they were placed beside the row, which is inside the panel.
    @Test func `beside the floating panel's edge, whatever the row's place in it`() {
        let panel = CGRect(x: 700, y: 0, width: 300, height: 600)
        let tile = CGRect(x: 860, y: 40, width: 120, height: 50)
        let right = PreviewPlacement.origin(size: size, row: tile, area: area, sidebarOnRight: true, panel: panel)
        #expect(right.x + area.minX + size.width <= panel.minX - 12 + 0.001, "left of the panel, not of the tile")
        let leftPanel = CGRect(x: 200, y: 0, width: 300, height: 600)
        let indented = CGRect(x: 260, y: 300, width: 200, height: 30)
        let left = PreviewPlacement.origin(
            size: size,
            row: indented,
            area: area,
            sidebarOnRight: false,
            panel: leftPanel
        )
        #expect(left.x + area.minX >= leftPanel.maxX + 12 - 0.001)
    }

    @Test func `kept inside the area at its top and bottom`() {
        let high = PreviewPlacement.origin(
            size: size,
            row: CGRect(x: 10, y: 0, width: 180, height: 20),
            area: area,
            sidebarOnRight: false
        )
        let low = PreviewPlacement.origin(
            size: size,
            row: CGRect(x: 10, y: 590, width: 180, height: 10),
            area: area,
            sidebarOnRight: false
        )
        #expect(high.y == 12 && low.y == 600 - 200 - 12)
    }

    @Test func `over a bar at the bottom, at the row's place, above the bar`() {
        let row = CGRect(x: 600, y: 610, width: 120, height: 30)
        let origin = PreviewPlacement.origin(size: size, row: row, area: area, sidebarOnRight: false)
        #expect(origin.x == 660 - 200 - 146 && origin.y == 600 - 200 - 12)
    }

    @Test func `with no row known, at the top corner of the sidebar's side`() {
        #expect(
            PreviewPlacement.origin(size: size, row: nil, area: area, sidebarOnRight: false) == CGPoint(x: 12, y: 12)
        )
    }
}
