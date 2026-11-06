import SunsetCore
import Testing

@testable import SunsetRender

@Suite("CPU renderer: pixel rows changed") struct CPURendererDirtyRowsTests {
    @Test func `the first frame changed every pixel row`() {
        var rig = CPURendererRig()
        rig.frame("hello", cursorVisible: false)
        #expect(rig.renderer.changedPixelRows == 0 ... rig.surface.height - 1)
    }

    @Test func `a frame that changes nothing changed no pixel row`() {
        var rig = CPURendererRig()
        rig.frame("hello", cursorVisible: false)
        rig.frame(cursorVisible: false)
        #expect(rig.renderer.changedPixelRows == nil)
    }

    @Test func `one changed text row is the pixel rows of that cell row, and no others`() {
        var rig = CPURendererRig()
        rig.frame("a\r\nb\r\nc", cursorVisible: false)
        rig.frame("\u{1B}[2;1Hx", cursorVisible: false)
        let top = metrics.paddingY + 1 * metrics.cellHeight
        #expect(rig.renderer.changedPixelRows == top ... top + metrics.cellHeight - 1)
    }

    @Test func `two rows that changed are the range from the first to the last`() {
        var rig = CPURendererRig()
        rig.frame("a\r\nb\r\nc\r\nd", cursorVisible: false)
        rig.frame("\u{1B}[1;1Hx\u{1B}[4;1Hy", cursorVisible: false)
        let first = metrics.paddingY
        let last = metrics.paddingY + 3 * metrics.cellHeight + metrics.cellHeight - 1
        #expect(rig.renderer.changedPixelRows == first ... last)
    }

    @Test func `a cursor that moved changed the row it left and the row it entered`() {
        var rig = CPURendererRig()
        rig.frame("a\r\nb\r\nc\r\nd", cursorVisible: true)  // the cursor is on the last row
        rig.frame("\u{1B}[2;1H", cursorVisible: true)  // and moves to the second
        let top = metrics.paddingY + 1 * metrics.cellHeight
        let bottom = metrics.paddingY + 4 * metrics.cellHeight - 1
        #expect(rig.renderer.changedPixelRows == top ... bottom)
    }
}
