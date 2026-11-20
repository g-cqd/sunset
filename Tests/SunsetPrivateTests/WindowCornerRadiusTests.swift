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

    /// What AppKit reports: 16 points on macOS 27.0.1 (measured here), 12 on macOS 26 (CI's macos-26-arm64 runner, 2026-11-20).
    private var standardRadius: Double {
        if #available(macOS 27, *) { 16 } else { 12 }
    }

    @Test func `a standard window has its system's radius, as AppKit reports it`() {
        #expect(WindowCornerRadius.of(window([.titled, .closable, .resizable])) == standardRadius)
        #expect(WindowCornerRadius.of(window([.titled, .closable, .resizable, .fullSizeContentView])) == standardRadius)
    }

    @Test func `a borderless window has square corners`() {
        #expect(WindowCornerRadius.of(window([.borderless])) == 0)
    }
}
