import SunsetCore
import Synchronization
import Testing

@testable import SunsetRender

@Suite("Frame renderer: presenting") struct FrameRendererPresentTests {
    @Test
    func
        `a frame is handed to the presenter with the pixel rows that changed, and a frame that changed nothing is not`()
        async
    {
        var terminal = Terminal(columns: 10, rows: 4)
        terminal.feed("hello")
        let presenter = PresentRecorder()
        let renderer = FrameRenderer(metrics: metrics, glyphs: BoxGlyphSource())
        let first = await renderer.present(terminal.screen, cursorVisible: false, textBlinkVisible: true, to: presenter)
        terminal.clearDirty()
        let second = await renderer.present(
            terminal.screen,
            cursorVisible: false,
            textBlinkVisible: true,
            to: presenter
        )
        terminal.feed("\u{1B}[3;1Hx")
        let third = await renderer.present(terminal.screen, cursorVisible: false, textBlinkVisible: true, to: presenter)
        #expect(first && !second && third)
        let calls = presenter.calls.withLock { $0 }
        #expect(calls.count == 2)
        #expect(calls.first == 0 ... metrics.surfaceSize(columns: 10, rows: 4).height - 1)
        #expect(
            calls.last == metrics.paddingY + 2 * metrics.cellHeight ... metrics.paddingY + 3 * metrics.cellHeight - 1
        )
    }
}
