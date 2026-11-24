import AppKit
import Testing
import WebKit

@testable import SunsetWeb

/// A page out of every window (a background tab, a tab being closed) is not on screen: a field it focuses is not told,
/// and nothing is shown for it (white paper §9: a page could otherwise have suggestions anchored to a view with no
/// window, which AppKit refuses by raising: n144).
extension PasswordFillTests {
    @Test func `a field focused by a page out of every window is not told`() async throws {
        let (_, view, host) = try await page()
        let window = try #require(view.window)
        view.removeFromSuperview()
        try await focus("u", in: view)
        // Back on screen: the next field's focus is told, and is the first.
        window.contentView = view
        try await focus("p", in: view)
        await host.wait(for: 1)
        #expect(host.events == ["focus password"])
    }
}
