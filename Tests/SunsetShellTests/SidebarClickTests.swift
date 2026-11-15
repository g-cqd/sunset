import AppKit
import SunsetMetrics
import SunsetPane
import SwiftUI
import Testing

@testable import SunsetShell

/// A click on a row of the sidebar, in a window (review of 2026-11-15, owner notes n15, n56, n59): the row is shown at the
/// click, not once a second click can no longer come.
@MainActor @Suite("A sidebar row, clicked", .serialized)
struct SidebarClickTests {
    let harness = TabsHarness()
    var tabs: TabsModel { harness.tabs }

    /// The sidebar in a window behind the others, 229 pt wide: its rows start under the header.
    func hosted() async -> NSWindow {
        _ = NSApplication.shared
        var settings = ShellSettings()
        settings.sidebar.documents = false
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 229, height: 400),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(
            rootView: TabSidebar(tabs: tabs, settings: settings) {}.frame(width: 229, height: 400)
        )
        window.orderBack(nil)
        for _ in 0 ..< 20 { try? await Task.sleep(for: .milliseconds(25)) }
        return window
    }

    /// Presses and releases at `point` (from the top left), `count` times as one multiple click.
    func click(_ window: NSWindow, at point: CGPoint, count: Int = 1) async {
        let at = CGPoint(x: point.x, y: (window.contentView?.bounds.height ?? 0) - point.y)
        for number in 1 ... count {
            for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
                if let event = NSEvent.mouseEvent(
                    with: type,
                    location: at,
                    modifierFlags: [],
                    timestamp: ProcessInfo.processInfo.systemUptime,
                    windowNumber: window.windowNumber,
                    context: nil,
                    eventNumber: 0,
                    clickCount: number,
                    pressure: 1
                ) {
                    window.sendEvent(event)
                }
                // Between a press and its release, and between two clicks; nothing after the last release.
                if type == .leftMouseDown || number < count { try? await Task.sleep(for: .milliseconds(20)) }
            }
        }
    }

    /// The most looks, 5 ms apart, a click may take: 50 ms. Counted in looks and not on a clock, so that a machine busy with
    /// other tests does not fail it; a click held for a second one takes about 70.
    static let atOnce = 10

    /// How many looks, 5 ms apart, until the condition held (0: it already did); nil when it did not within a second.
    func looks(until condition: () -> Bool) async -> Int? {
        for look in 0 ..< 200 {
            if condition() { return look }
            try? await Task.sleep(for: .milliseconds(5))
        }
        return nil
    }

    /// The middle of the row of the tab at `index`: the rows start under the header and are a row's height apart.
    func row(_ index: Int) -> CGPoint {
        let layout = ShellSettings().layout
        let top = SidebarHeader(layout: layout, margin: ShellSettings().sidebar.padding).height
        let height = Design.oneLineHeight(layout, height: Design.Size.tabRow)
        return CGPoint(x: 100, y: top + (height + layout.tabSpacing) * Double(index) + height / 2)
    }

    @Test func `a click shows the tab at once, without waiting for a second click`() async throws {
        tabs.newTab()
        tabs.newTab()
        tabs.newTab()
        let window = await hosted()
        defer { window.close() }
        #expect(tabs.workspace.selectedIndex == 2)
        await click(window, at: row(0))
        let took = try #require(await looks { tabs.workspace.selectedIndex == 0 }, "the click did nothing")
        #expect(took <= Self.atOnce, "the tab was shown \(took * 5) ms after the click")
    }

    @Test func `a double click still renames the row, and it is the row shown`() async throws {
        tabs.newTab()
        tabs.newTab()
        let window = await hosted()
        defer { window.close() }
        let first = tabs.workspace.items[0].id
        await click(window, at: row(0), count: 2)
        #expect(await looks { tabs.renamingRow == .tab(first) } != nil, "the double click did not rename")
        #expect(tabs.workspace.selectedIndex == 0)
    }
}
