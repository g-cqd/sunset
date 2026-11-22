import AppKit
import SunsetMetrics
import SunsetPane
import SwiftUI
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// "Pinned tabs don't align with edges of other tabs". The grid is laid out in the rows' width; its tiles reach both of
/// its edges, as a row does.
@MainActor
@Suite("The Pinned grid's edges")
struct PinnedGridEdgesTests {
    /// The first and last columns, in points, where a tile is drawn in the grid's middle line, rendered at `width`.
    private func drawnSpan(width: Double, pinned count: Int) throws -> (first: Double, last: Double, width: Double) {
        let pinned = FavoritesModel()
        let tabs = TabsModel()
        tabs.makeContent = { FakeContent($0) }
        tabs.pinned = pinned
        for _ in 0 ..< count {
            tabs.newTab()
            let id = try #require(tabs.workspace.selectedID)
            _ = try #require(tabs.pin(item: id))
        }
        tabs.newTab()
        let grid = PinnedGrid(tabs: tabs, layout: LayoutMetrics())
            .frame(width: width)
            .environment(\.colorScheme, .light)
        let renderer = ImageRenderer(content: grid)
        renderer.scale = 2
        let image = NSBitmapImageRep(cgImage: try #require(renderer.cgImage))
        let row = PinnedLayout.height  // the middle of the first row of tiles, at scale 2
        // What is behind the tiles: the top corner, outside the first tile's rounded corner whether or not the grid is inset.
        let behind = try #require(image.colorAt(x: 0, y: 0)?.usingColorSpace(.sRGB))
        let drawn = (0 ..< image.pixelsWide)
            .filter {
                guard let colour = image.colorAt(x: $0, y: Int(row))?.usingColorSpace(.sRGB) else { return false }
                return abs(colour.redComponent - behind.redComponent)
                    + abs(colour.greenComponent - behind.greenComponent)
                    + abs(colour.blueComponent - behind.blueComponent) > 0.05
            }
        let first = try #require(drawn.first)
        let last = try #require(drawn.last)
        return (Double(first) / 2, Double(last + 1) / 2, Double(image.pixelsWide) / 2)
    }

    @Test func `the tiles reach both edges of the rows' width`() throws {
        let span = try drawnSpan(width: 224, pinned: 4)
        #expect(span.width == 224, "\(span)")
        #expect(span.first == 0, "leading edge at \(span.first)")
        #expect(span.last == 224, "trailing edge at \(span.last)")
    }
}
