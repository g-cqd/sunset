import AppKit
import SunsetMetrics
import SwiftUI
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The top of a section's list: "documents sorting and adding buttons overlap with the search and the search makes no sense
/// with no documents existing". The title's row is as tall as its buttons, and the search field is there only when the section
/// has something to search.
@MainActor @Suite("The top of a section: its title, its buttons, its search") struct SectionTopTests {
    var docked: SidebarButtons {
        SidebarButtons(layout: LayoutMetrics(), margin: 4, panelRadius: nil)
    }
    var floating: SidebarButtons {
        SidebarButtons(layout: LayoutMetrics().floatingTabs, margin: 4, panelRadius: 12)
    }

    /// The heading drawn 240 pt wide: the buttons red, the field white, on black.
    func drawn(_ top: SectionTop) throws -> NSBitmapImageRep {
        let heading = SectionHeading(top: top, title: "Documents") {
            Color.red.frame(width: top.buttons.metrics.size.width, height: top.buttons.metrics.size.height)
        } field: {
            Color.white.frame(height: Design.Size.field)
        }
        let renderer = ImageRenderer(content: heading.frame(width: 240).background(Color.black))
        renderer.scale = 2
        return NSBitmapImageRep(cgImage: try #require(renderer.cgImage))
    }

    /// The rows of pixels with red in them (the buttons) and with white (the field).
    func rows(_ image: NSBitmapImageRep) -> (buttons: [Int], field: [Int]) {
        var buttons: [Int] = []
        var field: [Int] = []
        for y in 0 ..< image.pixelsHigh {
            var red = false
            var white = false
            for x in 0 ..< image.pixelsWide {
                guard let colour = image.colorAt(x: x, y: y) else { continue }
                if colour.redComponent > 0.8, colour.greenComponent > 0.8, colour.blueComponent > 0.8 {
                    white = true
                } else if colour.redComponent > 0.8, colour.greenComponent < 0.3 {
                    red = true
                }
            }
            if red { buttons.append(y) }
            if white { field.append(y) }
        }
        return (buttons, field)
    }

    @Test(arguments: [true, false])
    func `the title's row is as tall as the buttons in it, docked and floating`(underLights: Bool) {
        for buttons in [docked, floating] {
            let top = SectionTop(buttons: buttons, underLights: underLights, searchable: true)
            #expect(top.titleRow >= buttons.metrics.size.height, "\(top.titleRow) for \(buttons.metrics.size.height)")
        }
    }

    @Test(arguments: [true, false])
    func `the buttons end above the search field, with the tabs' spacing between`(underLights: Bool) throws {
        for buttons in [docked, floating] {
            let drawn = rows(try drawn(SectionTop(buttons: buttons, underLights: underLights, searchable: true)))
            let last = try #require(drawn.buttons.last)
            let first = try #require(drawn.field.first)
            #expect(first > last, "the field starts at \(first), the buttons end at \(last)")
            #expect(Double(first - last - 1) / 2 >= buttons.layout.tabSpacing - 1, "\(first - last - 1) px between")
        }
    }

    @Test func `with nothing to search there is no field, and the list starts that much higher`() throws {
        let with = SectionTop(buttons: docked, underLights: true, searchable: true)
        let without = SectionTop(buttons: docked, underLights: true, searchable: false)
        #expect(rows(try drawn(without)).field.isEmpty)
        #expect(!rows(try drawn(with)).field.isEmpty)
        #expect(with.listTop - without.listTop == Design.Size.field + docked.layout.tabSpacing)
        #expect(without.listTop >= docked.header.height + without.titleRow)
    }

    @Test func `the list starts where the heading ends, plus a breath`() throws {
        for searchable in [true, false] {
            let top = SectionTop(buttons: docked, underLights: true, searchable: searchable)
            let image = try drawn(top)
            #expect(abs(Double(image.pixelsHigh) / 2 + Design.Space.xs - top.listTop) <= 1, "\(image.pixelsHigh / 2)")
        }
    }

    @Test func `a section is searched when it has something, and the settings always`() {
        #expect(!SidebarSection.documents.isSearched(count: 0))
        #expect(SidebarSection.documents.isSearched(count: 1))
        #expect(!SidebarSection.history.isSearched(count: 0))
        #expect(!SidebarSection.downloads.isSearched(count: 0))
        #expect(SidebarSection.settings.isSearched(count: 0))
    }
}
