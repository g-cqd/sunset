import AppKit
import SunsetMetrics
import SwiftUI
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The sidebar with the Library open (the owner, 2026-11-15): the sidebar widens in place by a rail of glyphs at the window's
/// edge, with a gutter between the rail and the list; the list is as wide as the tabs were and is not made again.
@MainActor @Suite("The sidebar widening for the Library") struct LibraryFrameTests {
    var buttons: SidebarButtons {
        SidebarButtons(layout: LayoutMetrics(), margin: 4, panelRadius: nil)
    }

    /// The frame drawn 200 pt high: the list white, the rail red, on black; `open` shows the rail.
    func drawn(open: Bool, railLeading: Bool, list: Double = 220) throws -> NSBitmapImageRep {
        let frame = LibraryFrame(railLeading: railLeading, buttons: buttons, railShown: open) {
            Color.white
        } rail: {
            Color.red
        }
        let width = list + (open ? SectionRail.width(buttons) : 0)
        let renderer = ImageRenderer(content: frame.frame(width: width, height: 200).background(Color.black))
        renderer.scale = 1
        return NSBitmapImageRep(cgImage: try #require(renderer.cgImage))
    }

    /// Within a pixel: the gaps are in half points.
    func near(_ pixels: Int, _ points: Double) -> Bool {
        abs(Double(pixels) - points) <= 1
    }

    /// The columns of the middle row that are white (the list) and red (the rail).
    func columns(_ image: NSBitmapImageRep) -> (list: [Int], rail: [Int]) {
        var list: [Int] = []
        var rail: [Int] = []
        for x in 0 ..< image.pixelsWide {
            guard let colour = image.colorAt(x: x, y: 100) else { continue }
            if colour.redComponent > 0.8, colour.greenComponent > 0.8 {
                list.append(x)
            } else if colour.redComponent > 0.8 {
                rail.append(x)
            }
        }
        return (list, rail)
    }

    @Test func `the rail takes a button, its gap to the window's edge, and a gutter before the list`() {
        #expect(SectionRail.gutter >= 6, "a little space, not a hairline")
        #expect(SectionRail.width(buttons) == buttons.metrics.size.width + buttons.gap + SectionRail.gutter)
    }

    @Test
    func `closed, the list has the whole width; open, it keeps that width and the rail is beside it past a gutter`()
        throws
    {
        let closed = columns(try drawn(open: false, railLeading: false))
        #expect(closed.list.count == 220 && closed.rail.isEmpty)
        let open = columns(try drawn(open: true, railLeading: false))
        #expect(open.list.count == 220 && open.list.first == 0, "the list is as wide as the tabs were")
        let rail = try #require(open.rail.first)
        #expect(near(rail - 220, SectionRail.gutter), "the gutter: \(rail - 220)")
        #expect(near(open.rail.count, buttons.metrics.size.width), "\(open.rail.count)")
    }

    @Test func `with the sidebar on the left the rail is at the left, the window's edge`() throws {
        let open = columns(try drawn(open: true, railLeading: true))
        #expect(near(try #require(open.rail.first), buttons.gap), "the gap to the window's edge")
        let last = try #require(open.rail.last)
        #expect(near(try #require(open.list.first) - last - 1, SectionRail.gutter) && open.list.count == 220)
    }
}
