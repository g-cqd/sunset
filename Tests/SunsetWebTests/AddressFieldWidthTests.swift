import AppKit
import Foundation
import SwiftUI
import Testing

@testable import SunsetWeb
@testable import SunsetWebModel

/// The sidebar's address field "does not show the full length" of its text and the caret does not appear at its end. An
/// `NSTextField` asks for its text's width; given a long address it was laid out wider than the field, and its end (and
/// the caret there) fell outside, clipped by the field's shape.
@MainActor @Suite("The address field's width")
struct AddressFieldWidthTests {
    @Test func `a long address is laid out in the width given, not its own`() throws {
        let long = "https://example.org/" + String(repeating: "very/long/path/", count: 20)
        let view = AddressTextField(
            host: "example.org",
            address: long,
            focusNow: .constant(false),
            onSubmit: { _ in },
            onCancel: {},
            onEditing: { _ in }
        )
        // As in the sidebar: the lock before it, the row's width fixed.
        let host = NSHostingView(
            rootView: HStack(spacing: 4) {
                Image(systemName: "lock")
                view
                Spacer(minLength: 0)
            }
            .frame(width: 200, height: 22)
        )
        host.frame = CGRect(x: 0, y: 0, width: 200, height: 22)
        host.layoutSubtreeIfNeeded()
        let field = try #require(Self.field(in: host))
        let frame = field.convert(field.bounds, to: host)
        #expect(frame.maxX <= 200.5, "its end at \(frame.maxX) in 200")
        // Shown its host ("example.org", short), it still takes the row: typed in, the whole address has room, and the caret
        // at its end is in view.
        #expect(frame.width >= 150, "\(frame.width) wide: the host's width, not the row's")
    }

    private static func field(in view: NSView) -> AddressNSField? {
        if let field = view as? AddressNSField { return field }
        for child in view.subviews { if let found = field(in: child) { return found } }
        return nil
    }
}
