import AppKit
import Testing

@testable import SunsetWeb
@testable import SunsetWebModel

/// The owner's note n41 (2026-11-18): "focusing on the address bar to edit the text now completely changes the dimensions
/// and layout of the input". Typing in it leaves the editor where AppKit puts it; only a later change of the field's width
/// moves the editor's end with it (note n10), keeping AppKit's margin.
@MainActor @Suite("The address field while typed in")
struct AddressFieldEditorTests {
    private func field(width: Double) -> (NSWindow, AddressNSField) {
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 400, height: 60),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        let field = AddressNSField(frame: CGRect(x: 20, y: 20, width: width, height: 22))
        field.isBordered = false
        field.drawsBackground = false
        field.cell?.usesSingleLineMode = true
        field.address = "https://example.org/" + String(repeating: "long/path/", count: 20)
        field.host = "example.org"
        window.contentView?.addSubview(field)
        return (window, field)
    }

    /// The frame AppKit itself gives the editor of a plain field this wide.
    private func appKitFrame(width: Double) throws -> CGRect {
        let (window, plain) = (
            NSWindow(
                contentRect: CGRect(x: 0, y: 0, width: 400, height: 60),
                styleMask: [.titled],
                backing: .buffered,
                defer: false
            ), NSTextField(frame: CGRect(x: 20, y: 20, width: width, height: 22))
        )
        plain.isBordered = false
        plain.drawsBackground = false
        plain.cell?.usesSingleLineMode = true
        plain.cell?.isScrollable = true
        plain.stringValue = "x"
        window.contentView?.addSubview(plain)
        #expect(window.makeFirstResponder(plain))
        let editor = try #require(plain.currentEditor()?.superview)
        return editor.frame
    }

    @Test
    func
        `beginning to type leaves the editor's start where AppKit puts it, its end inside the field, after a layout too`()
        throws
    {
        let (window, field) = field(width: 200)
        _ = window
        field.beginTyping()
        field.layoutSubtreeIfNeeded()
        field.layout()
        let clip = try #require(field.currentEditor()?.superview)
        let appKit = try appKitFrame(width: 200)
        #expect(
            clip.frame.minX == appKit.minX && clip.frame.minY == appKit.minY && clip.frame.height == appKit.height,
            "\(clip.frame)"
        )
        // Its end at the field's alignment edge less the caret's margin (the owner's screenshot of 2026-11-19).
        #expect(
            abs(clip.frame.maxX - (200 - field.alignmentRectInsets.right - AddressNSField.caretMargin)) < 0.5,
            "\(clip.frame)"
        )
    }

    @Test func `narrowed while typed in, the editor's end follows the field's, keeping AppKit's margin`() throws {
        let (window, field) = field(width: 200)
        _ = window
        field.beginTyping()
        let clip = try #require(field.currentEditor()?.superview)
        let margin = 200 - clip.frame.maxX
        field.setFrameSize(CGSize(width: 150, height: 22))
        #expect(abs(clip.frame.maxX - (150 - margin)) < 0.5, "\(clip.frame) in 150, margin \(margin)")
        #expect(clip.frame.minX == (try appKitFrame(width: 200)).minX)
    }
}
