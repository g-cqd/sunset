import AemiKernel
import Testing

@testable import SunsetCore

/// The kitty graphics protocol, second part (roadmap 0010 C, ADR-0117): every delete kitty has (by cell, row, column,
/// cursor, layer, cell and layer, range of ids), the capitals freeing images left without a placement; a delete ending an
/// upload in progress; the quota taking images without a placement first; a part of an image shown (`x`, `y`, `w`, `h`),
/// from a point within its first cell (`X`, `Y`); each screen its own placements.
@Suite("kitty graphics: placements and deletes") struct KittyPlacementTests {
    /// A 20 × 6 terminal, cells of 10 × 20 pixels.
    private func terminal() -> Terminal {
        var t = Terminal(columns: 20, rows: 6)
        t.setCellPixelSize(width: 10, height: 20)
        return t
    }

    private func image(_ id: Int, _ width: Int = 20, _ height: Int = 20) -> String {
        let pixels = Base64.encodedString([UInt8](repeating: 0x7F, count: width * height * 4))
        return "\(esc)_Ga=t,q=2,f=32,i=\(id),s=\(width),v=\(height);\(pixels)\(esc)\\"
    }

    /// Image `id` shown at (`row`, `column`), 1-based as the cursor is moved, with `more` keys (2 × 1 cells by default).
    private func show(_ t: inout Terminal, _ id: Int, at row: Int, _ column: Int, _ more: String = "") {
        t.feed("\(esc)[\(row);\(column)H\(esc)_Ga=p,q=2,C=1,i=\(id)\(more.isEmpty ? "" : "," + more)\(esc)\\")
    }

    private func shown(_ t: Terminal) -> [UInt32] {
        t.screen.graphics.placements.map(\.image).sorted()
    }

    /// Three images: 1 at row 1 column 1, 2 at row 3 column 5 (z = -1), 3 at row 5 column 10 (z = 2), each 2 × 1 cells.
    private func three() -> Terminal {
        var t = terminal()
        t.feed(image(1) + image(2) + image(3))
        show(&t, 1, at: 1, 1)
        show(&t, 2, at: 3, 5, "z=-1")
        show(&t, 3, at: 5, 10, "z=2")
        return t
    }

    private func delete(_ t: inout Terminal, _ keys: String) {
        t.feed("\(esc)_Ga=d,q=2,\(keys)\(esc)\\")
    }

    @Test func `deleted by cell, row, column, cursor, layer, cell and layer, and range of ids`() {
        let cases: [(keys: String, left: [UInt32])] = [
            ("d=p,x=6,y=3", [1, 3]), ("d=p,x=7,y=3", [1, 2, 3]), ("d=y,y=5", [1, 2]), ("d=x,x=2", [2, 3]),
            ("d=z,z=-1", [1, 3]), ("d=q,x=5,y=3,z=2", [1, 2, 3]), ("d=q,x=5,y=3,z=-1", [1, 3]), ("d=r,x=2,y=3", [1])
        ]
        for (keys, left) in cases {
            var t = three()
            delete(&t, keys)
            #expect(shown(t) == left, "\(keys)")
            #expect(t.screen.graphics.images.count == 3, "\(keys): lowercase keeps the images")
        }
        var t = three()
        t.feed("\(esc)[5;11H")
        delete(&t, "d=c")
        #expect(shown(t) == [1, 2], "the cursor's cell")
    }

    @Test func `capitals free the images left without a placement, not those still shown elsewhere`() {
        var t = three()
        show(&t, 2, at: 6, 1)
        delete(&t, "d=Y,y=3")
        #expect(shown(t) == [1, 2, 3])
        #expect(t.screen.graphics.images[2] != nil, "still shown on row 6")
        delete(&t, "d=Y,y=6")
        #expect(t.screen.graphics.images[2] == nil && t.screen.graphics.images.count == 2)
        delete(&t, "d=R,x=1,y=3")
        #expect(t.screen.graphics.images.isEmpty && t.screen.graphics.placements.isEmpty)
    }

    @Test func `all: the placements on the screen, not those scrolled into the history`() {
        var t = three()
        t.feed("\(esc)[6;1H" + String(repeating: "\n", count: 3))
        delete(&t, "d=a")
        #expect(shown(t) == [1, 2], "images 1 and 2, scrolled off the screen, stay")
    }

    @Test func `a delete ends an upload in progress`() {
        var t = terminal()
        t.feed("\(esc)_Ga=t,q=2,f=24,i=9,s=2,v=1,m=1;AAAA\(esc)\\")
        delete(&t, "d=a")
        t.feed("\(esc)_Gm=0;AAAA\(esc)\\")
        #expect(t.screen.graphics.images[9] == nil)
    }

    @Test func `over the quota, images without a placement go first`() {
        var t = terminal()
        t.setGraphicsQuota(bytes: 3 * 20 * 20 * 4)
        t.feed(image(1) + image(2))
        show(&t, 1, at: 1, 1)
        t.feed(image(3) + image(4))
        #expect(t.screen.graphics.images[1] != nil, "shown: kept, though the oldest")
        #expect(t.screen.graphics.images[2] == nil && t.screen.graphics.images[4] != nil)
    }

    @Test func `a part of the image, from a point within the first cell`() throws {
        var t = terminal()
        t.feed(image(1, 40, 40))
        show(&t, 1, at: 1, 1, "x=10,y=5,w=25,h=30,X=6,Y=12")
        let placed = try #require(t.screen.graphics.placements.first)
        #expect([placed.sourceX, placed.sourceY, placed.sourceWidth, placed.sourceHeight] == [10, 5, 25, 30])
        #expect([placed.offsetX, placed.offsetY, placed.width, placed.height] == [6, 12, 25, 30])
        // 6 + 25 pixels across cells of 10: 4 columns; 12 + 30 down cells of 20: 3 rows.
        #expect([placed.columns, placed.rows] == [4, 3])
        show(&t, 1, at: 1, 1, "x=35,w=99,X=50")
        let clipped = try #require(t.screen.graphics.placements.last)
        #expect([clipped.sourceX, clipped.sourceWidth, clipped.offsetX] == [35, 5, 9], "within the image and the cell")
    }

    @Test func `each screen its own placements: the alternate's are gone when it is left, the main's come back`() {
        var t = terminal()
        t.feed(image(1) + image(2))
        show(&t, 1, at: 1, 1)
        t.feed("\(esc)[?1049h")
        #expect(shown(t).isEmpty, "the alternate screen starts without the main's")
        show(&t, 2, at: 2, 2)
        #expect(shown(t) == [2])
        t.feed("\(esc)[?1049l")
        #expect(shown(t) == [1])
        t.feed("\(esc)[?1049h")
        #expect(shown(t).isEmpty, "entered again, cleared as its cells are")
    }
}
