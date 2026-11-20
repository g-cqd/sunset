import AppKit
import SwiftUI
import Testing

@testable import SunsetShell

/// The owner's note n62: in the site settings popover "icons are not in a regular, consistently sized container, so text
/// misaligns across lines". Rows whose symbols differ in width start their titles at one place.
@MainActor @Suite("A row's label: one box for every symbol")
struct RowLabelStyleTests {
    private final class Starts {
        var values: [Int: Double] = [:]
    }

    /// Where each row's title starts, laid out in a window with `style`.
    private func titleStarts(_ style: some LabelStyle) -> [Double] {
        let symbols = ["hand.raised", "theatermasks", "rectangle.on.rectangle", "bell"]
        let starts = Starts()
        let view = VStack(alignment: .leading) {
            ForEach(symbols.indices, id: \.self) { index in
                Label {
                    Text("Row")
                        .onGeometryChange(for: Double.self, of: { $0.frame(in: .global).minX }) {
                            starts.values[index] = $0
                        }
                } icon: {
                    Image(systemName: symbols[index])
                }
            }
        }
        .labelStyle(style)
        .frame(width: 300, height: 200, alignment: .topLeading)
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 300, height: 200),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        let host = NSHostingView(rootView: view)
        host.frame = window.contentLayoutRect
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        return symbols.indices.compactMap { starts.values[$0] }
    }

    @Test func `the titles of rows with symbols of different widths start at one place`() {
        let starts = titleStarts(.row)
        #expect(starts.count == 4)
        #expect(Set(starts.map { ($0 * 2).rounded() }).count == 1, "\(starts)")
    }

    /// What it fixes: with the system's style the titles start where each symbol ends.
    @Test func `with the system's style they do not`() {
        let starts = titleStarts(.titleAndIcon)
        #expect(starts.count == 4)
        #expect(Set(starts.map { ($0 * 2).rounded() }).count > 1, "\(starts)")
    }
}
