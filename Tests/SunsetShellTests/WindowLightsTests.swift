import AppKit
import SunsetTestSupport
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The window's three buttons, kept where Sunset wants them (AppKit lays its title bar out again when it sees fit, and the
/// buttons were left where it put them). They stay AppKit's, in its title bar; they are moved within it, and put back each
/// time anything moves them.
@MainActor @Suite("The window's buttons, kept in place", .serialized)
struct WindowLightsTests {
    static let types: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]

    /// A window with no decorations, as Sunset's: its content under a transparent title bar. Behind the others.
    func window(width: Double = 900) -> NSWindow {
        _ = NSApplication.shared
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isReleasedWhenClosed = false
        window.contentView = NSView(frame: NSRect(x: 0, y: 0, width: width, height: 500))
        window.orderBack(nil)
        return window
    }

    func buttons(_ window: NSWindow) -> [NSButton] {
        Self.types.compactMap { window.standardWindowButton($0) }
    }

    /// Each button's top left corner, from the window's.
    func corners(_ window: NSWindow) -> [CGPoint] {
        buttons(window)
            .map { button in
                let inWindow = button.convert(button.bounds, to: nil)
                return CGPoint(x: inWindow.minX.rounded(), y: (window.frame.height - inWindow.maxY).rounded())
            }
    }

    /// AppKit lays the window out (its own timing, not Sunset's).
    func settle() async {
        RealWait.runLoop(for: .milliseconds(60))
    }

    func place(_ inset: Double, _ top: Double, fromRight: Bool = false, visible: Bool = true) -> WindowLights.Placement
    {
        WindowLights.Placement(inset: inset, top: top, fromRight: fromRight, centred: false, visible: visible)
    }

    @Test func `the lights are put where asked: from the left in the system's order, from the right mirrored`() async {
        let window = window()
        defer { window.close() }
        let lights = WindowLights(window: window)
        let pitch = lights.spacing
        lights.placement = place(20, 14)
        #expect(
            corners(window) == [CGPoint(x: 20, y: 14), CGPoint(x: 20 + pitch, y: 14), CGPoint(x: 20 + 2 * pitch, y: 14)]
        )
        let width = buttons(window)[0].frame.width
        lights.placement = place(11, 11, fromRight: true)
        let close = 900 - 11 - width
        #expect(
            corners(window) == [
                CGPoint(x: close, y: 11), CGPoint(x: close - pitch, y: 11), CGPoint(x: close - 2 * pitch, y: 11)
            ]
        )
    }

    @Test func `they stay in the title bar: nothing is taken out of it`() async {
        let window = window()
        defer { window.close() }
        let before = buttons(window).map { $0.superview.map(ObjectIdentifier.init) }
        let lights = WindowLights(window: window)
        lights.placement = place(11, 30, fromRight: true)
        await settle()
        #expect(buttons(window).map { $0.superview.map(ObjectIdentifier.init) } == before)
        #expect(corners(window).allSatisfy { $0.y == 30 }, "lower than the title bar was tall: it is made taller")
    }

    @Test func `a resize, after which AppKit lays its title bar out again, leaves them where they were put`() async {
        let window = window()
        defer { window.close() }
        let lights = WindowLights(window: window)
        lights.placement = place(11, 11, fromRight: true)
        let width = buttons(window)[0].frame.width
        window.setFrame(NSRect(x: 0, y: 0, width: 1000, height: 560), display: true)
        await settle()
        #expect(corners(window).first == CGPoint(x: 1000 - 11 - width, y: 11), "\(corners(window))")
        lights.placement = place(11, 11)
        window.setFrame(NSRect(x: 0, y: 0, width: 800, height: 400), display: true)
        await settle()
        #expect(corners(window).first == CGPoint(x: 11, y: 11))
    }

    @Test func `whatever moves a button, it is put back`() async {
        let window = window()
        defer { window.close() }
        let lights = WindowLights(window: window)
        lights.placement = place(40, 12)
        let wanted = corners(window)
        // What AppKit does when it tiles its title bar: each button back at its own place.
        for (index, button) in buttons(window).enumerated() {
            button.setFrameOrigin(NSPoint(x: 9 + 23 * Double(index), y: 9))
        }
        await settle()
        #expect(corners(window) == wanted)
        let placed = lights.placements
        lights.place()
        lights.place()
        #expect(lights.placements == placed, "nothing is moved when nothing was")
    }

    @Test func `hidden, they are out of reach and faded; shown again, they are back`() async throws {
        let window = window()
        defer { window.close() }
        // Layer-backed, as in the app: the buttons fade, and are put out of reach once the fade is over.
        for button in buttons(window) {
            button.wantsLayer = true
        }
        let time = TestTime()
        let lights = WindowLights(window: window)
        lights.runtime = time.runtime
        lights.placement = place(11, 11)
        let hiding = time.mark()
        lights.placement = place(11, 11, visible: false)
        try await time.release(after: .milliseconds(200), since: hiding, count: buttons(window).count)
        #expect(corners(window).allSatisfy { $0.x < 0 }, "\(corners(window))")
        window.setFrame(NSRect(x: 0, y: 0, width: 950, height: 500), display: true)
        await settle()
        #expect(corners(window).allSatisfy { $0.x < 0 }, "AppKit's layout does not bring them back")
        lights.placement = place(11, 11)
        #expect(corners(window).first == CGPoint(x: 11, y: 11))
        #expect(buttons(window).allSatisfy { $0.layer.map { $0.opacity == 1 } ?? true })
    }

    @Test func `with no placement AppKit's own layout is left alone`() async {
        let window = window()
        defer { window.close() }
        let own = corners(window)
        let lights = WindowLights(window: window)
        await settle()
        #expect(corners(window) == own && lights.placements == 0)
        window.setFrame(NSRect(x: 0, y: 0, width: 950, height: 500), display: true)
        await settle()
        #expect(corners(window) == own)
    }
}
