import SunsetCore
import Testing

@testable import SunsetRender

@Suite("CPU renderer: blink phase") struct CPURendererBlinkTests {
    private func frame(_ rig: inout CPURendererRig, blinkVisible: Bool) -> Int {
        let before = rig.renderer.rowsDrawn
        rig.terminal.clearDirty()
        rig.renderer.render(
            rig.terminal.screen,
            into: &rig.surface,
            cursorVisible: false,
            textBlinkVisible: blinkVisible
        )
        return rig.renderer.rowsDrawn - before
    }

    @Test func `a blink phase that changes nothing on screen draws no row`() {
        var rig = CPURendererRig()
        rig.frame("plain text\r\nmore text", cursorVisible: false)
        #expect(frame(&rig, blinkVisible: false) == 0)
        #expect(frame(&rig, blinkVisible: true) == 0)
    }

    @Test func `only the rows with blinking text are drawn when the phase changes`() {
        var rig = CPURendererRig()
        rig.frame("plain\r\n\u{1B}[5mblinks\u{1B}[0m\r\nplain", cursorVisible: false)
        #expect(frame(&rig, blinkVisible: false) == 1)
        #expect(frame(&rig, blinkVisible: true) == 1)
    }

    @Test func `the blinking text is hidden and shown with the phase, as before`() {
        var rig = CPURendererRig()
        rig.frame("\u{1B}[5mxx", cursorVisible: false)
        let shown = rig.surface
        _ = frame(&rig, blinkVisible: false)
        #expect(rig.surface.pixels != shown.pixels)
        _ = frame(&rig, blinkVisible: true)
        #expect(rig.surface.pixels == shown.pixels)
    }

    @Test func `a row stops being redrawn once its blinking text is gone`() {
        var rig = CPURendererRig()
        rig.frame("\u{1B}[5mblinks", cursorVisible: false)
        rig.frame("\u{1B}[1;1H\u{1B}[0m      ", cursorVisible: false)
        #expect(frame(&rig, blinkVisible: false) == 0)
    }

    @Test func `phase frames equal a fresh renderer's, with blinking text on several rows`() {
        var rig = CPURendererRig()
        rig.frame("a\u{1B}[5mb\u{1B}[0mc\r\n\u{1B}[5;31md\r\nplain", cursorVisible: false)
        _ = frame(&rig, blinkVisible: false)
        var fresh = Surface(width: rig.surface.width, height: rig.surface.height)
        CPURenderer(metrics: metrics, glyphs: BoxGlyphSource())
            .render(rig.terminal.screen, into: &fresh, cursorVisible: false, textBlinkVisible: false)
        #expect(fresh.pixels == rig.surface.pixels)
    }
}
