import CoreGraphics
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// Where each icon of the picker's grid is ("the rendering and scrolling through the list should also be
/// instantaneous"). The grid is one view that draws the cells in sight and finds a cell from a point by arithmetic:
/// nothing is made for the thousands that are not shown.
@Suite("The icon grid's geometry")
struct IconGridLayoutTests {
    @Test func `as many columns as fit the width, centred; as many rows as hold every icon`() {
        let layout = IconGridLayout(width: 308, count: 6751)
        #expect(layout.columns == 9 && layout.rows == 751)
        #expect(layout.height == 751 * IconGridLayout.pitch.height)
        #expect(layout.inset == (308 - 9 * IconGridLayout.pitch.width) / 2)
        #expect(IconGridLayout(width: 308, count: 0).rows == 0 && IconGridLayout(width: 308, count: 9).rows == 1)
        #expect(IconGridLayout(width: 308, count: 10).rows == 2)
        #expect(IconGridLayout(width: 10, count: 5).columns == 1, "never none")
    }

    @Test func `a cell is found from a point, and a point from a cell; outside the cells there is none`() {
        let layout = IconGridLayout(width: 308, count: 25)
        for index in [0, 8, 9, 24] {
            let rect = layout.rect(of: index)
            #expect(layout.index(at: CGPoint(x: rect.midX, y: rect.midY)) == index)
        }
        #expect(layout.rect(of: 9).minY == IconGridLayout.pitch.height && layout.rect(of: 9).minX == layout.inset)
        #expect(layout.inset == 1 && layout.index(at: CGPoint(x: 0.5, y: 5)) == nil, "the margin")
        #expect(
            layout.index(at: CGPoint(x: layout.rect(of: 8).midX, y: layout.rect(of: 24).midY)) == nil,
            "past the last"
        )
        #expect(layout.index(at: CGPoint(x: 50, y: -3)) == nil && layout.index(at: CGPoint(x: 50, y: 9999)) == nil)
    }

    @Test func `the cells to draw for a part of the view are the rows it touches, and no more`() {
        let layout = IconGridLayout(width: 308, count: 6751)
        let pitch = IconGridLayout.pitch.height
        #expect(layout.indices(in: CGRect(x: 0, y: 0, width: 308, height: pitch)) == 0 ..< 9)
        #expect(layout.indices(in: CGRect(x: 0, y: pitch * 10 + 1, width: 308, height: pitch * 2)) == 90 ..< 117)
        #expect(layout.indices(in: CGRect(x: 0, y: pitch * 750, width: 308, height: 500)) == 6750 ..< 6751)
        #expect(layout.indices(in: CGRect(x: 0, y: -500, width: 308, height: 100)).isEmpty)
        #expect(layout.indices(in: CGRect(x: 0, y: 99_999, width: 308, height: 100)).isEmpty)
    }
}
