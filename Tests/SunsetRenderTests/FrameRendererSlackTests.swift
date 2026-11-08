import SunsetCore
import Testing

@testable import SunsetRender

@Suite("Frame renderer: pixels beyond the last whole cell") struct FrameRendererSlackTests {
    @Test func `the surface covers the whole view and the leftover pixels get the background colour`() async {
        var terminal = Terminal(columns: 10, rows: 4)
        terminal.feed("hello")
        let renderer = FrameRenderer(metrics: metrics, glyphs: BoxGlyphSource())
        let grid = metrics.surfaceSize(columns: 10, rows: 4)
        let view = FrameView(extraPixels: (width: 7, height: 5))
        let frame = await renderer.frame(for: terminal.screen, cursorVisible: false, textBlinkVisible: true, view: view)
        #expect(frame.width == grid.width + 7 && frame.height == grid.height + 5)
        func pixel(_ x: Int, _ y: Int) -> [UInt8] {
            let at = (y * frame.width + x) * 4
            return Array(frame.bytes[at ..< at + 4])
        }
        let background = pixel(frame.width - 1, 0)
        #expect(pixel(frame.width - 1, frame.height - 1) == background, "bottom right corner")
        #expect(pixel(0, frame.height - 1) == background, "bottom left, in the extra rows")
        #expect(pixel(grid.width + 3, grid.height / 2) == background, "right of the grid, in the extra columns")
    }

    @Test func `without extra pixels the surface is the grid's`() async {
        let terminal = Terminal(columns: 10, rows: 4)
        let renderer = FrameRenderer(metrics: metrics, glyphs: BoxGlyphSource())
        let frame = await renderer.frame(for: terminal.screen, cursorVisible: false, textBlinkVisible: true)
        let grid = metrics.surfaceSize(columns: 10, rows: 4)
        #expect(frame.width == grid.width && frame.height == grid.height)
    }
}
