import AppKit
import SunsetMetrics
import SunsetPane
import SwiftUI
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// One scroll view holds the Pinned grid, the Favorites and Today's tabs; it takes what the header and the bottom bar
/// leave, and never pushes them out.
@MainActor
@Suite("What scrolls in the sidebar")
struct SidebarScrollTests {
    /// The sidebar laid out in a borderless window, 229 by 400 pt: its scroll views, top to bottom, in the window's
    /// coordinates from the top.
    private func scrollViews(_ tabs: TabsModel, height: Double = 400) -> [CGRect] {
        _ = NSApplication.shared
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 229, height: height),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        let host = NSHostingView(
            rootView: TabSidebar(tabs: tabs, settings: ShellSettings()) {}.frame(width: 229, height: height)
        )
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        var found: [CGRect] = []
        func walk(_ view: NSView) {
            if let scroll = view as? NSScrollView {
                let frame = scroll.convert(scroll.bounds, to: nil)
                found.append(CGRect(x: frame.minX, y: height - frame.maxY, width: frame.width, height: frame.height))
            }
            view.subviews.forEach(walk)
        }
        walk(host)
        window.close()
        return found.sorted { $0.minY < $1.minY }
    }

    @Test func `one scroll view holds the grid, the Favorites and the tabs, inside a short window`() throws {
        let pinned = FavoritesModel()
        let harness = TabsHarness()
        let tabs = harness.tabs
        tabs.pinned = pinned
        tabs.newTab()
        let first = try #require(tabs.workspace.selectedID)
        _ = try #require(tabs.pin(item: first))
        for _ in 0 ..< 6 {
            tabs.newTab()
            let next = try #require(tabs.workspace.selectedID)
            _ = try #require(tabs.keep(item: next))
        }
        for _ in 0 ..< 3 { tabs.newTab() }
        #expect(tabs.pinnedEntries.count == 1 && tabs.workspace.count == 3)

        let layout = ShellSettings().layout
        let header = SidebarHeader(layout: layout, margin: ShellSettings().sidebar.padding).height
        let height = 180.0
        let scrolls = scrollViews(tabs, height: height)
        #expect(scrolls.count == 1, "one scroll view: \(scrolls)")
        let list = try #require(scrolls.first, "a scroll view")
        // Its top right under the header: the grid is in it.
        #expect(list.minY < header + PinnedLayout.height, "the scroll view's top at \(list.minY)")
        // And it ends in the window: nothing below it is pushed out.
        #expect(list.maxY <= height + 0.5, "the scroll view's bottom at \(list.maxY) in \(height)")
    }
}
