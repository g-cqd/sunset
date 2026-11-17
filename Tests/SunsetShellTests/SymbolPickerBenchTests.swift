import AppKit
import Foundation
import SunsetPane
import SwiftUI
import Testing

@testable import SunsetShell

/// What the symbol picker costs (the owner, 2026-11-17: "not really performant right now at loading all symbols"): reading
/// the catalog, a search for each key typed, and drawing the grid. Off unless `SUNSET_BENCH=1`; run in release:
/// `SUNSET_BENCH=1 swift test -c release --filter SymbolPickerBench`.
@MainActor
@Suite("The symbol picker's cost", .enabled(if: ProcessInfo.processInfo.environment["SUNSET_BENCH"] == "1"))
struct SymbolPickerBenchTests {
    static func milliseconds(_ body: () -> Void) -> Double {
        let start = ContinuousClock.now
        body()
        let took = ContinuousClock.now - start
        return Double(took.components.seconds) * 1000 + Double(took.components.attoseconds) / 1e15
    }

    static func percentiles(_ samples: [Double]) -> String {
        let sorted = samples.sorted()
        func at(_ share: Double) -> Double { sorted[min(Int(Double(sorted.count) * share), sorted.count - 1)] }
        return String(format: "p50 %.2f ms, p90 %.2f ms, max %.2f ms", at(0.5), at(0.9), sorted[sorted.count - 1])
    }

    @Test func `reading the catalog, and a search for each key of a word`() {
        var catalog = SymbolCatalog(symbols: [])
        let loads = (0 ..< 15).map { _ in Self.milliseconds { catalog = SymbolCatalog.load() } }
        print("catalog: \(catalog.symbols.count) symbols; read: \(Self.percentiles(loads))")
        for word in ["f", "fo", "fol", "folder", "arrow up", "zzzz", "trmnl"] {
            var found = 0
            let samples = (0 ..< 15).map { _ in Self.milliseconds { found = catalog.search(word).count } }
            print("search \"\(word)\": \(found) found; \(Self.percentiles(samples))")
        }
        let before = Self.footprint()
        let kept = (0 ..< 8).map { _ in IconCatalogs.load() }
        print("the catalogs kept in memory, symbols and emoji: \((Self.footprint() - before) / kept.count / 1024) KB")
        let reads = (0 ..< 15).map { _ in Self.milliseconds { _ = EmojiCatalog.load() } }
        print("emoji: \(kept[0].emoji.emoji.count); read: \(Self.percentiles(reads))")
        let emojiSearch = (0 ..< 15).map { _ in Self.milliseconds { _ = kept[0].emoji.search("face") } }
        print("emoji search \"face\": \(Self.percentiles(emojiSearch))")
        var inCategory = 0
        let category = (0 ..< 15)
            .map { _ in
                Self.milliseconds { inCategory = catalog.search("", in: "devices").count }
            }
        print("category devices: \(inCategory); \(Self.percentiles(category))")
    }

    /// The grid in a window that is never on screen, with the catalogs already read: every symbol shown and drawn; what a
    /// key typed costs it (the list changed, laid out, drawn); and scrolling, two rows a step, drawn at each step, through
    /// symbols never drawn before and back over the same.
    @Test func `the grid: a change of the list, and scrolling, each laid out and drawn`() async {
        let catalogs = IconCatalogs.load()
        let all = catalogs.symbols.search("").map(IconChoice.init)
        let some = catalogs.symbols.search("fo").map(IconChoice.init)
        let emoji = catalogs.emoji.emoji.map(IconChoice.init)
        var first: [Double] = []
        var changes: [Double] = []
        var fresh: [Double] = []
        var again: [Double] = []
        var faces: [Double] = []
        var arrived: [Double] = []
        for _ in 0 ..< 5 {
            let scroll = IconGridScrollView(frame: NSRect(x: 0, y: 0, width: 308, height: 220))
            let window = NSWindow(
                contentRect: scroll.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.contentView = scroll
            let grid = scroll.grid
            grid.chosen = "folder"
            first.append(Self.milliseconds { Self.show(all, in: scroll) })
            // Drawing does not wait for the symbols: how long until those in sight are all there.
            let asked = ContinuousClock.now
            while !grid.isComplete { try? await Task.sleep(for: .microseconds(500)) }
            let took = ContinuousClock.now - asked
            arrived.append(Double(took.components.attoseconds) / 1e15)
            for list in [some, all, some, all] { changes.append(Self.milliseconds { Self.show(list, in: scroll) }) }
            let steps = stride(from: 64.0, through: 64.0 * 60, by: 64.0).map { NSPoint(x: 0, y: $0) }
            // A frame apart at 120 Hz: two rows a frame is a fast fling (7,700 points a second).
            for point in steps {
                fresh.append(Self.milliseconds { Self.scroll(grid, to: point) })
                try? await Task.sleep(for: .milliseconds(8))
            }
            for point in steps.reversed().prefix(30) {
                again.append(Self.milliseconds { Self.scroll(grid, to: point) })
                try? await Task.sleep(for: .milliseconds(8))
            }
            faces.append(Self.milliseconds { Self.show(emoji, in: scroll) })
            for point in steps.prefix(40) {
                faces.append(Self.milliseconds { Self.scroll(grid, to: point) })
                try? await Task.sleep(for: .milliseconds(8))
            }
            window.contentView = nil
        }
        print("grid, \(all.count) symbols, shown and drawn the first time: \(Self.percentiles(first))")
        print("grid, then until the symbols in sight are rendered: \(Self.percentiles(arrived))")
        print("grid, the list changed (\(some.count) or all), laid out and drawn: \(Self.percentiles(changes))")
        print("grid, a scroll step drawn, symbols never drawn: \(Self.percentiles(fresh))")
        print("grid, a scroll step drawn, symbols drawn before: \(Self.percentiles(again))")
        print("grid, \(emoji.count) emoji shown, then scroll steps drawn: \(Self.percentiles(faces))")
    }

    static func show(_ items: [IconChoice], in scroll: IconGridScrollView) {
        scroll.grid.show(items)
        scroll.layoutSubtreeIfNeeded()
        draw(scroll.grid)
    }

    static func scroll(_ grid: IconGridView, to point: NSPoint) {
        grid.scroll(point)
        draw(grid)
    }

    static func footprint() -> Int {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            unsafe pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                unsafe task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? Int(info.phys_footprint) : 0
    }

    /// Draws what is in sight into a bitmap: what the window server would be given.
    static func draw(_ view: NSView) {
        let rect = view.visibleRect
        guard let bitmap = view.bitmapImageRepForCachingDisplay(in: rect) else { return }
        view.cacheDisplay(in: rect, to: bitmap)
    }
}
