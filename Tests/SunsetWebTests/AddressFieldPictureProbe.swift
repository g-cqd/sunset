import AppKit
import Foundation
import SunsetTestSupport
import SwiftUI
import Testing

@testable import SunsetWeb

/// A picture of the sidebar's field typed in, at the sidebar's width (`SUNSET_ADDRESS_PICTURE`: a probe, never in the suite).
@MainActor @Suite("The address field typed in (probe)")
struct AddressFieldPictureProbe {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["SUNSET_ADDRESS_PICTURE"] != nil))
    func `typed in, at the sidebar's width`() async throws {
        let long = "https://example.org/" + String(repeating: "very/long/path/", count: 6) + "END"
        let page = WebContent(url: URL(string: long), settings: WebSettings(applicationName: "x"))
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 230, height: 40),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        defer { window.close() }
        let host = NSHostingView(
            rootView: AddressField(content: page, reload: true).frame(width: 214, height: 30).padding(8)
        )
        window.contentView = host
        window.makeKeyAndOrderFront(nil)
        await RealWait.pass(.milliseconds(300))
        page.wantsAddress = true
        await RealWait.pass(.milliseconds(500))
        let field = try #require(Self.field(in: host))
        let editor = try #require(field.currentEditor() as? NSTextView)
        editor.setSelectedRange(NSRange(location: (field.stringValue as NSString).length, length: 0))
        editor.scrollRangeToVisible(editor.selectedRange())
        // As the field is laid out again (its row's buttons go while it is typed in).
        field.needsLayout = true
        host.layoutSubtreeIfNeeded()
        await RealWait.pass(.milliseconds(300))
        let frame = field.convert(field.bounds, to: host)
        let length = (field.stringValue as NSString).length
        var last = CGRect.zero
        if let layout = editor.layoutManager, let container = editor.textContainer {
            let glyphs = layout.glyphRange(
                forCharacterRange: NSRange(location: length - 1, length: 1),
                actualCharacterRange: nil
            )
            last = layout.boundingRect(forGlyphRange: glyphs, in: container)
        }
        print(
            "probe-address: field",
            frame,
            "editor visible",
            editor.visibleRect,
            "text width",
            editor.frame.width,
            "last letter",
            last,
            "padding",
            editor.textContainer?.lineFragmentPadding ?? -1,
            "inset",
            editor.textContainerInset,
            "clip",
            editor.enclosingScrollView?.contentView.bounds ?? editor.superview?.bounds ?? .zero
        )
        // The end of the address is in what the field shows (the caret after it at the edge, as AppKit puts it).
        #expect(
            last.maxX <= editor.visibleRect.maxX + 0.5,
            "last letter ends at \(last.maxX), shown to \(editor.visibleRect.maxX)"
        )
        if let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) {
            host.cacheDisplay(in: host.bounds, to: rep)
            try rep.representation(using: .png, properties: [:])?
                .write(to: URL(fileURLWithPath: "/tmp/address-typed.png"))
        }
    }

    private static func field(in view: NSView) -> AddressNSField? {
        if let field = view as? AddressNSField { return field }
        for child in view.subviews { if let found = field(in: child) { return found } }
        return nil
    }
}
