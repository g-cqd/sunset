import SunsetCore
import Testing

@testable import SunsetRender

@Suite("CPU renderer: cursor over a translucent background") struct CPURendererCursorAlphaTests {
    private func premultiplied(_ red: UInt8, _ green: UInt8, _ blue: UInt8, alpha: UInt8) -> UInt32 {
        func scale(_ value: UInt8) -> UInt32 { (UInt32(value) * UInt32(alpha) + 127) / 255 }
        return UInt32(alpha) << 24 | scale(blue) << 16 | scale(green) << 8 | scale(red)
    }

    @Test(arguments: [(5, "bar"), (3, "underline")])
    func `a bar or underline cursor leaves the rest of its cell as translucent as the rest of the window`(
        style: Int,
        name: String
    ) {
        var rig = CPURendererRig()
        rig.backgroundAlpha = 100
        rig.terminal.feed("\u{1B}]11;#c86432\u{7}\u{1B}[\(style) q")
        rig.frame(cursorVisible: true)
        let want = premultiplied(200, 100, 50, alpha: 100)
        // The cursor is at the first cell; a pixel in the middle of that cell is neither the bar (left edge) nor the underline (bottom).
        let cellWidth = rig.surface.width / 10
        let cellHeight = rig.surface.height / 4
        let middle = (cellHeight / 3) * rig.surface.width + cellWidth / 2
        #expect(rig.surface.pixels[middle] == want, "\(name): got \(String(rig.surface.pixels[middle], radix: 16))")
    }

    @Test func `a block cursor still fills its cell with the cursor colour`() {
        var rig = CPURendererRig()
        rig.backgroundAlpha = 100
        rig.terminal.feed("\u{1B}]11;#c86432\u{7}\u{1B}[2 q")
        rig.frame(cursorVisible: true)
        let cellWidth = rig.surface.width / 10
        let cellHeight = rig.surface.height / 4
        let middle = (cellHeight / 3) * rig.surface.width + cellWidth / 2
        #expect(rig.surface.pixels[middle] != premultiplied(200, 100, 50, alpha: 100))
    }
}
