import Testing

@testable import SunsetPrivate

@Suite("Window blur") struct WindowBlurTests {
    @Test func `the radius is kept inside 0 to 100 and whole`() {
        #expect(WindowBlur.clampedRadius(-5) == 0)
        #expect(WindowBlur.clampedRadius(0) == 0)
        #expect(WindowBlur.clampedRadius(12.6) == 13)
        #expect(WindowBlur.clampedRadius(100) == 100)
        #expect(WindowBlur.clampedRadius(5000) == 100)
        #expect(WindowBlur.clampedRadius(.nan) == 0)
        #expect(WindowBlur.clampedRadius(.infinity) == 100)
    }

    @Test func `on this system the calls are found by name`() {
        #expect(
            WindowBlur.isAvailable,
            "the window server's connection and blur symbols were not found: the blur falls back to a material"
        )
    }

    @Test func `a window that does not exist is refused by the system, not crashed on`() {
        // 0 is not a window number: the call returns an error code (or does nothing); the point is that it returns.
        _ = WindowBlur.setRadius(20, forWindowNumber: 0)
        #expect(Bool(true))
    }
}
