import AppKit
import Testing

@testable import SunsetShell

/// The icon grid as it is drawn (the owner, 2026-11-17: instantaneous, symbols and emoji): what is in sight is drawn,
/// symbols once they are rendered, and a click picks the cell under it.
@MainActor
@Suite("The icon grid, drawn")
struct IconGridViewTests {
    private func grid(_ items: [IconChoice]) -> (scroll: IconGridScrollView, window: NSWindow) {
        let scroll = IconGridScrollView(frame: NSRect(x: 0, y: 0, width: 308, height: 220))
        let window = NSWindow(contentRect: scroll.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = scroll
        scroll.grid.show(items)
        scroll.layoutSubtreeIfNeeded()
        return (scroll, window)
    }

    /// How many pixels of each cell's place have something drawn, for the cells in sight.
    private func inked(_ grid: IconGridView, over alpha: CGFloat = 0.5) throws -> [Int] {
        let rect = grid.visibleRect
        let bitmap = try #require(grid.bitmapImageRepForCachingDisplay(in: rect))
        grid.cacheDisplay(in: rect, to: bitmap)
        let scale = CGFloat(bitmap.pixelsWide) / rect.width
        return grid.layout.indices(in: rect)
            .map { index in
                let cell = grid.layout.rect(of: index).offsetBy(dx: -rect.minX, dy: -rect.minY)
                var count = 0
                for y in stride(from: Int(cell.minY * scale), to: min(Int(cell.maxY * scale), bitmap.pixelsHigh), by: 1)
                {
                    for x in stride(
                        from: Int(cell.minX * scale),
                        to: min(Int(cell.maxX * scale), bitmap.pixelsWide),
                        by: 1
                    )
                    where (bitmap.colorAt(x: x, y: y)?.alphaComponent ?? 0) > alpha { count += 1 }
                }
                // As if every point were one pixel: the same on a screen of any scale (the suite failed on a 1x
                // screen with counts made for 2x, 2026-11-17).
                return Int(CGFloat(count) / (scale * scale))
            }
    }

    private func symbols(_ names: [String]) -> [IconChoice] {
        names.map { IconChoice(SymbolCatalog.Symbol(name: $0, keywords: [], categories: [])) }
    }

    @Test func `symbols and emoji are drawn once rendered, each in its cell; drawing waits for none`() async throws {
        let names = ["folder", "trash", "house", "arrow.up", "star", "bolt", "gear", "doc", "book", "tray", "flag"]
        let (scroll, window) = grid(
            symbols(names) + [IconChoice(EmojiCatalog.Emoji(text: "\u{1F680}", name: "rocket"))]
        )
        let grid = scroll.grid
        #expect(grid.frame.size == CGSize(width: 308, height: 2 * IconGridLayout.pitch.height))
        let first = try inked(grid)
        #expect(first.count == 12 && first.allSatisfy { $0 == 0 }, "drawing does not wait for the icons")
        for _ in 0 ..< 400 where !grid.isComplete { try await Task.sleep(for: .milliseconds(5)) }
        let then = try inked(grid)
        #expect(then.allSatisfy { $0 >= 8 } && then[11] > 40, "every icon in its cell, the emoji a full face: \(then)")
        window.contentView = nil
    }

    @Test func `the chosen cell is marked, and a click on a cell picks it`() async throws {
        let (scroll, window) = grid(symbols(["folder", "trash", "house"]))
        let grid = scroll.grid
        for _ in 0 ..< 400 where !grid.isComplete { try await Task.sleep(for: .milliseconds(5)) }
        let plain = try inked(grid, over: 0.1)
        grid.chosen = "trash"
        let marked = try inked(grid, over: 0.1)
        #expect(marked[1] > plain[1] + 125 && marked[0] == plain[0], "the cell's ground is filled: \(plain) \(marked)")
        var picked: [String] = []
        grid.onPick = { picked.append($0.id) }
        let centre = grid.layout.rect(of: 2)
        let point = grid.convert(CGPoint(x: centre.midX, y: centre.midY), to: nil)
        for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
            let event = try #require(
                NSEvent.mouseEvent(
                    with: type,
                    location: point,
                    modifierFlags: [],
                    timestamp: 0,
                    windowNumber: window.windowNumber,
                    context: nil,
                    eventNumber: 0,
                    clickCount: 1,
                    pressure: 1
                )
            )
            if type == .leftMouseDown { grid.mouseDown(with: event) } else { grid.mouseUp(with: event) }
        }
        #expect(picked == ["house"])
        // To accessibility the cells in sight are buttons by name, and pressing one picks it.
        let cells = (grid.accessibilityChildren() ?? []).compactMap { $0 as? NSAccessibilityElement }
        #expect(cells.map { $0.accessibilityLabel() } == ["folder", "trash", "house"])
        #expect(cells.allSatisfy { $0.accessibilityRole() == .button && $0.isAccessibilityEnabled() })
        #expect(cells[1].isAccessibilitySelected())
        #expect(cells[0].accessibilityPerformPress() && picked == ["house", "folder"])
        window.contentView = nil
    }
}
