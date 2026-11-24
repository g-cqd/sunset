import AppKit
import SunsetPane
import SunsetTestSupport
import SwiftUI
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// A probe, not a test: what one switch of tab costs with 40 tabs, in the real sidebar in a window (n56, t298). Runs only
/// with SUNSET_PROBE=1, and means something only in release (`swift test -c release -Xswiftc -enable-testing`); it prints
/// percentiles and asserts nothing.
@MainActor
@Suite("Tab switch probe", .serialized, .enabled(if: ProcessInfo.processInfo.environment["SUNSET_PROBE"] != nil))
struct TabSwitchProbe {
    private func percentiles(_ samples: [Double]) -> String {
        let sorted = samples.sorted()
        func at(_ p: Double) -> Double { sorted[min(sorted.count - 1, Int(p * Double(sorted.count)))] }
        return String(
            format: "n=%d p50=%.2f ms p95=%.2f ms max=%.2f ms",
            sorted.count,
            at(0.5),
            at(0.95),
            sorted.last ?? 0
        )
    }

    @Test func `a switch in the model, and in the sidebar in a window`() async throws {
        _ = NSApplication.shared
        let harness = TabsHarness()
        let tabs = harness.tabs
        for index in 0 ..< 40 { tabs.newTab(.terminal(directory: "/home/dev/p\(index)")) }
        let ids = tabs.workspace.items.map(\.id)

        // 1. The model alone.
        var model: [Double] = []
        for round in 0 ..< 400 {
            let id = ids[round % ids.count]
            let start = ContinuousClock.now
            tabs.select(item: id)
            model.append(Double((ContinuousClock.now - start).components.attoseconds) / 1e15)
        }
        print("PROBE model   select(item:):            \(percentiles(model))")

        // 2. The sidebar drawn: a switch, then the layout and the drawing it caused.
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 229, height: 900),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(
            rootView: TabSidebar(tabs: tabs, settings: ShellSettings()) {}.frame(width: 229, height: 900)
        )
        window.orderBack(nil)
        window.contentView?.layoutSubtreeIfNeeded()
        await RealWait.pass(.milliseconds(800))
        var drawn: [Double] = []
        for round in 0 ..< 200 {
            let id = ids[(round * 7) % ids.count]
            let start = ContinuousClock.now
            tabs.select(item: id)
            window.contentView?.layoutSubtreeIfNeeded()
            window.displayIfNeeded()
            CATransaction.flush()
            drawn.append(Double((ContinuousClock.now - start).components.attoseconds) / 1e15)
            await RealWait.pass(.milliseconds(10))
        }
        print("PROBE sidebar select + layout + display: \(percentiles(drawn))")
        window.close()
    }
}
