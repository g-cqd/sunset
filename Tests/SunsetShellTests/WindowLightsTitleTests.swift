import AppKit
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The window's buttons while its title changes (seen 2026-11-15 in the app: going from a tab to another, whose title is
/// another, left the zoom button at AppKit's place, the top left, under the content; close and minimise stayed).
@MainActor @Suite("The window's buttons when the title changes", .serialized)
struct WindowLightsTitleTests {
    let base = WindowLightsTests()

    @Test func `a new title, after which AppKit lays its title bar out again, leaves the three where they were put`()
        async
    {
        let window = base.window()
        defer { window.close() }
        let lights = WindowLights(window: window)
        lights.placement = base.place(11, 11, fromRight: true)
        await base.settle()
        let wanted = base.corners(window)
        for title in ["plain.txt", "Untitled", "/tmp", "a much longer title than the others, to be sure it is laid out"]
        {
            window.title = title
            #expect(base.corners(window) == wanted, "at once after \(title): \(base.corners(window))")
            await base.settle()
            #expect(base.corners(window) == wanted, "after \(title): \(base.corners(window))")
        }
    }

    @Test func `so does a file named for the title bar, and none`() async {
        let window = base.window()
        defer { window.close() }
        let lights = WindowLights(window: window)
        lights.placement = base.place(11, 11, fromRight: true)
        await base.settle()
        let wanted = base.corners(window)
        window.representedURL = URL(fileURLWithPath: "/tmp/plain.txt")
        window.title = "plain.txt"
        await base.settle()
        #expect(base.corners(window) == wanted, "\(base.corners(window))")
        window.representedURL = nil
        window.title = "Untitled"
        await base.settle()
        #expect(base.corners(window) == wanted, "\(base.corners(window))")
    }
}
