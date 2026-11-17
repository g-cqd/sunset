import AppKit
import Foundation
import SunsetMetrics
import SunsetPane
import SwiftUI
import Testing

@testable import SunsetShell

/// The owner, 2026-11-17 (roadmap 0035 I): calls to action "below the address bar": what the app puts there pushes the rows
/// down, as tall as it is.
@MainActor
@Suite("Calls to action under the sidebar's field")
struct SidebarNoticesTests {
    /// The top of the sidebar's scroll view, laid out with `notices` under the field.
    private func listTop(notices: AnyView?) -> Double {
        _ = NSApplication.shared
        let tabs = TabsModel()
        tabs.makeContent = { FakeContent($0) }
        tabs.newTab()
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 229, height: 400),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        let host = NSHostingView(
            rootView: TabSidebar(
                tabs: tabs,
                settings: ShellSettings(),
                accessory: AnyView(Color.gray),
                notices: notices
            ) {}
            .frame(width: 229, height: 400)
        )
        window.contentView = host
        // Twice: the calls to action's height is measured in the first pass and moves the rows in the next.
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date())
        host.layoutSubtreeIfNeeded()
        var tops: [Double] = []
        func walk(_ view: NSView) {
            if let scroll = view as? NSScrollView {
                tops.append(400 - Double(scroll.convert(scroll.bounds, to: nil).maxY))
            }
            view.subviews.forEach(walk)
        }
        walk(host)
        window.close()
        return tops.max() ?? -1
    }

    @Test func `the rows start below what is under the field, by its height`() {
        let without = listTop(notices: nil)
        let with = listTop(notices: AnyView(Color.red.frame(height: 50)))
        #expect(without > 0)
        #expect(with >= without + 50, "\(without) then \(with)")
    }
}
