import SunsetCore
import SunsetTestSupport
import Testing

@testable import SunsetRender

/// Placeholder cells drawn by the CPU renderer (roadmap 0010 E): the image they name over them, fitted and centred, and no
/// glyph for `U+10EEEE`. Cells are 8 × 16 pixels, so an image of 1 × 2 pixels fills its cells.
@Suite("CPU renderer: Unicode placeholders") struct CPURendererPlaceholderTests {
    private let red: [UInt8] = [255, 0, 0, 255]

    /// Image 7, 1 × 2 red (a cell's shape), given a virtual placement over `columns` × `rows` cells, then its cells written as ask
    /// writes them.
    private func picture(columns: Int, rows: Int, at row: Int = 1) -> String {
        // kitty's first three marks, for rows and columns 0 to 2.
        let mark = { (number: Int) in ["\u{0305}", "\u{030D}", "\u{030E}"][number] }
        let lines = (0 ..< rows)
            .map { line in
                "\u{1B}[\(row + line);1H" + (0 ..< columns).map { "\u{10EEEE}" + mark(line) + mark($0) }.joined()
            }
        return KittyImages.show(
            id: 7,
            width: columns,
            height: 2 * rows,
            rgba: red,
            options: "U=1,c=\(columns),r=\(rows)"
        )
            + "\u{1B}[38;2;0;0;7m" + lines.joined() + "\u{1B}[0m"
    }

    @Test func `the cells draw the image over them, and nothing beyond`() {
        var rig = CPURendererRig(10, 4)
        rig.frame(picture(columns: 2, rows: 2), cursorVisible: false)
        #expect(rig.surface[0, 0] == RGB(255, 0, 0))
        #expect(rig.surface[15, 31] == RGB(255, 0, 0), "2 × 2 cells of 8 × 16")
        #expect(rig.surface[16, 0] == black)
        #expect(rig.surface[0, 32] == black)
    }

    @Test func `under the image, below it, no glyph is drawn for U+10EEEE`() {
        var rig = CPURendererRig(10, 4)
        rig.frame(
            KittyImages.show(id: 7, width: 1, height: 2, rgba: red, options: "U=1,c=1,r=1,z=-1")
                + "\u{1B}[38;2;0;0;7m\u{10EEEE}\u{0305}\u{0305}\u{1B}[0m",
            cursorVisible: false
        )
        for x in 0 ..< 8 {
            for y in 0 ..< 16 {
                #expect(rig.surface[x, y] == RGB(255, 0, 0), "pixel \(x), \(y): no glyph over the image")
            }
        }
    }

    @Test func `a square image in a tall cell is centred, as kitty draws it`() {
        var rig = CPURendererRig(10, 4)
        rig.frame(
            KittyImages.show(id: 7, width: 1, height: 1, rgba: red, options: "U=1,c=1,r=1")
                + "\u{1B}[38;2;0;0;7m\u{10EEEE}\u{0305}\u{0305}\u{1B}[0m",
            cursorVisible: false
        )
        #expect(rig.surface[0, 3] == black && rig.surface[0, 12] == black, "4 pixels above and below")
        #expect(rig.surface[0, 4] == RGB(255, 0, 0) && rig.surface[7, 11] == RGB(255, 0, 0))
    }

    @Test func `it scrolls with its cells`() {
        var rig = CPURendererRig(10, 4)
        rig.frame(picture(columns: 1, rows: 1, at: 3), cursorVisible: false)
        #expect(rig.surface[2, 2 * 16 + 2] == RGB(255, 0, 0))
        rig.frame("\u{1B}[4;1H\n\n", cursorVisible: false)
        #expect(rig.surface[2, 2] == RGB(255, 0, 0), "two lines up, with its cells")
        #expect(rig.surface[2, 2 * 16 + 2] == black)
    }
}
