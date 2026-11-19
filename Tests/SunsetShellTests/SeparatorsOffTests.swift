import AppKit
import SunsetPane
import SwiftUI
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The owner, 2026-11-19: "disable the rendering of the separators between pinned and favorites and standard tabs". With
/// `sidebar.separators` off the sidebar draws no line between its sections; it draws the same otherwise.
@MainActor @Suite("The sidebar's separators, off")
struct SeparatorsOffTests {
    private func picture(separators: Bool) throws -> NSBitmapImageRep {
        let harness = TabsHarness()
        let tabs = harness.tabs
        tabs.pinned = FavoritesModel()
        tabs.newTab()
        _ = tabs.pin(item: try #require(tabs.workspace.selectedID))
        tabs.newTab()
        _ = tabs.keep(item: try #require(tabs.workspace.selectedID))
        tabs.newTab()
        var settings = ShellSettings()
        settings.sidebar.separators = separators
        _ = NSApplication.shared
        let size = CGSize(width: 229, height: 300)
        let window = NSWindow(
            contentRect: CGRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        let host = NSHostingView(
            rootView: TabSidebar(tabs: tabs, settings: settings) {}.frame(width: size.width, height: size.height)
                .background(Color.black).environment(\.colorScheme, .dark)
        )
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
        let rep = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: rep)
        window.close()
        return rep
    }

    /// Rows of the picture that hold a thin line: brighter than the background across most of the width, and no taller
    /// than a few pixels (a row's fill is taller).
    private func lines(_ rep: NSBitmapImageRep) -> Int {
        var bright: [Bool] = []
        for y in 0 ..< rep.pixelsHigh {
            var lit = 0
            for x in stride(from: rep.pixelsWide / 4, to: rep.pixelsWide * 3 / 4, by: 2) {
                if let color = rep.colorAt(x: x, y: y), color.brightnessComponent > 0.08 { lit += 1 }
            }
            bright.append(lit > rep.pixelsWide / 6)
        }
        var count = 0
        var run = 0
        for lit in bright + [false] {
            if lit {
                run += 1
            } else {
                if run > 0, run <= 3 { count += 1 }
                run = 0
            }
        }
        return count
    }

    @Test func `the two section lines drawn when on, gone when off`() throws {
        let onPicture = try picture(separators: true)
        let offPicture = try picture(separators: false)
        let on = lines(onPicture)
        let off = lines(offPicture)
        // The selected tab's outline is two thin lines in both; the separators, under the grid and under the Favorites,
        // are the two more.
        #expect(on - off == 2, "with separators \(on) thin lines, without \(off)")
    }
}
