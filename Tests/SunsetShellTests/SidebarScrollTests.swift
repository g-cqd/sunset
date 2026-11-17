import AppKit
import SunsetMetrics
import SunsetPane
import SwiftUI
import Testing

@testable import SunsetShell

/// The owner, 2026-11-17 (roadmap 0035 F): "Scrolling for tabs should only happen for today's tabs not pinned and
/// favorites". The Pinned grid and the Favorites stay where they are; the scroll view holds Today's tabs alone.
@MainActor
@Suite("What scrolls in the sidebar")
struct SidebarScrollTests {
    /// The sidebar laid out in a borderless window, 229 by 400 pt: its scroll views, top to bottom, in the window's
    /// coordinates from the top.
    private func scrollViews(_ tabs: TabsModel) -> [CGRect] {
        _ = NSApplication.shared
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 229, height: 400),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        let host = NSHostingView(
            rootView: TabSidebar(tabs: tabs, settings: ShellSettings()) {}.frame(width: 229, height: 400)
        )
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        var found: [CGRect] = []
        func walk(_ view: NSView) {
            if let scroll = view as? NSScrollView {
                let frame = scroll.convert(scroll.bounds, to: nil)
                found.append(CGRect(x: frame.minX, y: 400 - frame.maxY, width: frame.width, height: frame.height))
            }
            view.subviews.forEach(walk)
        }
        walk(host)
        window.close()
        return found.sorted { $0.minY < $1.minY }
    }

    @Test func `the scroll view starts below the Pinned grid and the Favorites`() throws {
        let pinned = FavoritesModel()
        let harness = TabsHarness()
        let tabs = harness.tabs
        tabs.pinned = pinned
        tabs.newTab()
        let first = try #require(tabs.workspace.selectedID)
        _ = try #require(tabs.pin(item: first))
        tabs.newTab()
        let second = try #require(tabs.workspace.selectedID)
        _ = try #require(tabs.keep(item: second))
        for _ in 0 ..< 3 { tabs.newTab() }
        #expect(tabs.pinnedEntries.count == 1 && !tabs.favorites.favorites.isEmpty && tabs.workspace.count == 3)

        let layout = ShellSettings().layout
        let header = SidebarHeader(layout: layout, margin: ShellSettings().sidebar.padding).height
        let row = Design.oneLineHeight(layout, height: Design.Size.tabRow)
        let scrolls = scrollViews(tabs)
        let list = try #require(scrolls.last, "a scroll view")
        // Below the header, the grid's row of tiles and the favourite's row at least.
        #expect(list.minY >= header + PinnedLayout.height + row, "the scroll view's top at \(list.minY)")
    }
}
