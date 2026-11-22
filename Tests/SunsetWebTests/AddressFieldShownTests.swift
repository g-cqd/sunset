import AppKit
import SunsetMetrics
import SunsetShell
import SunsetTestSupport
import SwiftUI
import Testing

@testable import SunsetWeb
@testable import SunsetWebModel

/// Seen 2026-11-19 in the sidebar's field:
/// - under the pointer, the host ran under Copy and Reload ("idmsa.apple.c" and the copy glyph over it): the text was masked
///   for a guessed width of the buttons, shorter than theirs;
/// - typed in, the caret at the end of a long address, its last letters were cut by the field's rounded edge
///   ("…a0110d07f757&rv=("): an `NSTextField` draws past the frame SwiftUI gives it.
/// The field's text now ends before its buttons, truncated in its middle so the end of the host (whose site it is) stays
/// seen, and is clipped to its own frame while typed in.
@MainActor @Suite("The address field: what it shows")
struct AddressFieldShownTests {
    private static let long =
        "https://idmsa.apple.com/appleauth/auth/authorize/signin?frame_id=auth-0c5b1d7e"
        + "&language=en_US&iframeId=auth-0c5b1d7e&client_id=a0110d07f757&rv=1"
    /// The field's width and padding in the sidebar (a tab's), and its outer margin here.
    private static let width = 167.0
    private static let padding = 8.0
    private static let margin = 8.0

    private func shown(hovering: Bool) -> (NSWindow, NSHostingView<AnyView>, WebContent) {
        let page = WebContent(url: URL(string: Self.long), settings: WebSettings(applicationName: "x"))
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: Self.width + 2 * Self.margin, height: 46),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: .darkAqua)
        let field = AddressField(content: page, reload: true, hovering: hovering)
            .environment(\.controlRadius, 8)
            .environment(\.controlPadding, Self.padding)
            .environment(\.controlHeight, 32)
        let host = NSHostingView(rootView: AnyView(field.frame(width: Self.width, height: 30).padding(Self.margin)))
        window.contentView = host
        window.makeKeyAndOrderFront(nil)
        host.layoutSubtreeIfNeeded()
        return (window, host, page)
    }

    /// Where the field's content ends, inside its padding.
    private static var contentEnd: Double {
        margin + width - padding
    }

    @Test func `under the pointer the text ends before Copy and Reload`() throws {
        let (window, host, _) = shown(hovering: true)
        defer { window.close() }
        let field = try #require(Self.field(in: host))
        #expect(field.stringValue == "idmsa.apple.com")
        let laid = field.convert(field.alignmentRect(forFrame: field.bounds), to: host).maxX
        // Copy and Reload: two glyph buttons, a close button's size each (20 points by default).
        let buttons = Self.contentEnd - 2 * LayoutMetrics().closeButtonSize
        #expect(laid <= buttons + 0.5, "the text ends at \(laid), the buttons begin at \(buttons)")
    }

    @Test func `typed in, the caret at the end, the last letter and the caret are inside the field's content`() throws {
        let (window, host, _) = shown(hovering: false)
        defer { window.close() }
        let field = try #require(Self.field(in: host))
        field.beginTyping()
        let editor = try #require(field.currentEditor() as? NSTextView)
        editor.moveToEndOfDocument(nil)
        host.layoutSubtreeIfNeeded()
        let layout = try #require(editor.layoutManager)
        let container = try #require(editor.textContainer)
        let length = (editor.string as NSString).length
        let glyphs = layout.glyphRange(
            forCharacterRange: NSRange(location: length - 1, length: 1),
            actualCharacterRange: nil
        )
        var last = layout.boundingRect(forGlyphRange: glyphs, in: container)
        last.origin.x += editor.textContainerOrigin.x
        // The caret is drawn after the last letter, a point wide.
        let end = editor.convert(last, to: host).maxX + 1
        #expect(end <= Self.contentEnd + 0.5, "the caret ends at \(end), the field's content at \(Self.contentEnd)")
        field.endTyping()
    }

    @Test(.macOS27)
    func `typing starts with the whole address selected and its start shown, after a change of width too`() throws {
        let (window, host, _) = shown(hovering: false)
        defer { window.close() }
        let field = try #require(Self.field(in: host))
        field.beginTyping()
        let editor = try #require(field.currentEditor() as? NSTextView)
        #expect(editor.selectedRange() == NSRange(location: 0, length: (Self.long as NSString).length))
        let start = editor.visibleRect.minX
        #expect(start < 3, "scrolled to \(start): the address's tail shown, not its start")
        field.setFrameSize(CGSize(width: field.frame.width + 30, height: field.frame.height))
        field.setFrameSize(CGSize(width: field.frame.width - 50, height: field.frame.height))
        #expect(editor.visibleRect.minX == start, "scrolled to \(editor.visibleRect.minX) after a resize")
        field.endTyping()
    }

    static func field(in view: NSView) -> AddressNSField? {
        if let field = view as? AddressNSField { return field }
        for child in view.subviews { if let found = field(in: child) { return found } }
        return nil
    }
}
