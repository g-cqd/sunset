import AppKit
import SunsetMetrics
import SwiftUI
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// Where a row says its document has edits that are not saved: at the row's end, just before the close button.
@MainActor
@Suite("The edited mark of a sidebar row")
struct SidebarRowEditedTests {
    static let width = 240.0

    /// The row drawn off screen at 1x, on black.
    func drawn(title: String, edited: Bool, closeShown: Bool = false) throws -> NSBitmapImageRep {
        let model = FakeContent()
        model.title = title
        model.isEdited = edited
        let row = SidebarRow(
            model: model,
            selected: false,
            keepCloseVisible: closeShown,
            parts: TabParts(icon: false, title: true, directory: false, progress: false),
            layout: LayoutMetrics(),
            open: false
        ) {}
        let renderer = ImageRenderer(
            content: row.frame(width: Self.width).background(Color.black).environment(\.colorScheme, .dark)
        )
        renderer.scale = 1
        return NSBitmapImageRep(cgImage: try #require(renderer.cgImage))
    }

    /// The columns with something drawn in them, in a band around the row's middle line.
    func inked(_ image: NSBitmapImageRep, in columns: Range<Int>) -> [Int] {
        let middle = image.pixelsHigh / 2
        return columns.filter { x in
            (middle - 2 ... middle + 2).contains { y in (image.colorAt(x: x, y: y)?.brightnessComponent ?? 0) > 0.25 }
        }
    }

    /// The columns the mark is on when the button is not shown: its end as far from the row's as the icon is from the row's start.
    var atTheEnd: Range<Int> {
        let end = Int(Self.width - LayoutMetrics().tabPaddingLeading)
        return end - Int(Design.Size.editedMark) - 1 ..< end + 1
    }

    /// Where the close button starts, when it shows.
    func buttonLeading(_ image: NSBitmapImageRep) -> Int {
        Int(Self.width - Double(image.pixelsHigh) / 2 - LayoutMetrics().closeButtonSize / 2)
    }

    @Test func `with no close button shown the mark is at the row's end, and nothing keeps the button's place`() throws
    {
        let image = try drawn(title: "a", edited: true)
        #expect(!inked(image, in: atTheEnd).isEmpty, "nothing is drawn at the row's end")
        #expect(
            inked(image, in: 18 ..< atTheEnd.lowerBound).isEmpty,
            "the mark is neither after the title nor before a button"
        )
        #expect(inked(try drawn(title: "a", edited: false), in: 18 ..< Int(Self.width)).isEmpty, "no edits, no mark")

        let long = String(repeating: "tides and harbours ", count: 6)
        let resting = try drawn(title: long, edited: true)
        let reach = inked(resting, in: 0 ..< atTheEnd.lowerBound).max() ?? 0
        let hovered = try drawn(title: long, edited: true, closeShown: true)
        let shorter = inked(hovered, in: 0 ..< buttonLeading(hovered) - 14).max() ?? 0
        #expect(
            reach > shorter + 12,
            "the title has the button's place while the button is not shown: \(reach), \(shorter)"
        )
        #expect(reach < atTheEnd.lowerBound - 2, "and it stops before the mark: \(reach)")
    }

    @Test func `with the close button shown the mark is just before it, and the title stops before the mark`() throws {
        let long = String(repeating: "tides and harbours ", count: 6)
        let hovered = try drawn(title: long, edited: true, closeShown: true)
        let leading = buttonLeading(hovered)
        let mark = inked(hovered, in: leading - 14 ..< leading)
        #expect(mark.count >= 4 && mark.count <= 8, "the mark alone is there, the title is not under it: \(mark)")
        #expect(!inked(hovered, in: leading ..< Int(Self.width)).isEmpty, "the button is drawn")
    }
}
