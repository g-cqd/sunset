import AppKit
import Testing

@testable import SunsetPrivate

@Suite("Window corner radius") @MainActor struct WindowCornerRadiusTests {
    private func window(_ style: NSWindow.StyleMask) -> NSWindow {
        _ = NSApplication.shared
        return NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 100),
            styleMask: style,
            backing: .buffered,
            defer: true
        )
    }

    @Test func `a standard window has 16 points, as AppKit reports it on this system`() {
        #expect(WindowCornerRadius.of(window([.titled, .closable, .resizable])) == 16)
        #expect(WindowCornerRadius.of(window([.titled, .closable, .resizable, .fullSizeContentView])) == 16)
    }

    @Test func `a borderless window has square corners`() {
        #expect(WindowCornerRadius.of(window([.borderless])) == 0)
    }
}
