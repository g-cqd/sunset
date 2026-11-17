import AppKit
import Foundation
import SwiftUI
import Testing

@testable import SunsetShell

/// The owner, 2026-11-17: "for all scrollviews that we use, bouncing should not be enabled if there's no reason to have
/// scrolling". A scroll view whose content fits does not bounce; one whose content overflows does.
@MainActor
@Suite("Scroll views bounce only when they scroll", .serialized)
struct ScrollBounceTests {
    /// The elasticity AppKit is given for a SwiftUI scroll view of `rows` 30 pt rows in a 200 pt window, with the app's rule.
    private func elasticity(rows: Int) throws -> NSScrollView.Elasticity {
        _ = NSApplication.shared
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 200, height: 200),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        let host = NSHostingView(
            rootView: ScrollView {
                VStack(spacing: 0) { ForEach(0 ..< rows, id: \.self) { _ in Color.gray.frame(height: 30) } }
            }
            .bouncesOnlyWhenScrolling()
            .frame(width: 200, height: 200)
        )
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        for _ in 0 ..< 5 {
            RunLoop.main.run(until: Date().addingTimeInterval(0.02))
            host.layoutSubtreeIfNeeded()
        }
        var found: NSScrollView?
        func walk(_ view: NSView) {
            if found == nil, let scroll = view as? NSScrollView { found = scroll }
            view.subviews.forEach(walk)
        }
        walk(host)
        window.close()
        return try #require(found).verticalScrollElasticity
    }

    @Test func `content that fits does not bounce; content that overflows does`() throws {
        #expect(try elasticity(rows: 3) == .none)
        #expect(try elasticity(rows: 30) != .none)
    }
}
