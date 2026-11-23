import AemiKernel
import Testing

@testable import SunsetCore

/// kitty's Unicode placeholders (roadmap 0010 E): an image given a virtual placement (`U=1`) is drawn by the cells holding
/// `U+10EEEE` in the colour naming it, fitted into its cells keeping its proportions, centred. ask draws pictures so.
@Suite("kitty graphics: Unicode placeholders") struct KittyPlaceholderTests {
    /// A 20 × 6 terminal, cells of 10 × 20 pixels.
    private func terminal() -> Terminal {
        var t = Terminal(columns: 20, rows: 6)
        t.setCellPixelSize(width: 10, height: 20)
        return t
    }

    /// Image `id`, `width` × `height` RGBA pixels, given a virtual placement over `columns` × `rows` cells.
    private func virtual(_ t: inout Terminal, _ id: Int, _ width: Int, _ height: Int, columns: Int, rows: Int) {
        let pixels = Base64.encodedString([UInt8](repeating: 0x7F, count: width * height * 4))
        t.feed("\(esc)_Ga=t,q=2,f=32,i=\(id),s=\(width),v=\(height);\(pixels)\(esc)\\")
        t.feed("\(esc)_Ga=p,q=2,U=1,i=\(id),c=\(columns),r=\(rows)\(esc)\\")
    }

    private func mark(_ number: Int) -> String {
        Unicode.Scalar(PlaceholderDiacritics.all[number]).map { String(Character($0)) } ?? ""
    }

    /// `count` placeholder cells of virtual row `row` from virtual column `first`, as ask writes them: each with both marks.
    private func cells(row: Int, from first: Int = 0, count: Int) -> String {
        (first ..< first + count).map { "\u{10EEEE}" + mark(row) + mark($0) }.joined()
    }

    /// The colour naming image `id` (its low 24 bits).
    private func color(_ id: Int) -> String {
        "\(esc)[38;2;\((id >> 16) & 0xFF);\((id >> 8) & 0xFF);\(id & 0xFF)m"
    }

    private func shown(_ t: Terminal) -> [ImagePlacement] {
        let first = t.screen.scrollbackCount
        return t.screen.placeholderPlacements(lines: first ..< first + 6)
    }

    @Test func `a virtual placement keeps the cursor where it was and shows nothing by itself`() {
        var t = terminal()
        t.feed("\(esc)[3;5H")
        virtual(&t, 7, 20, 20, columns: 4, rows: 2)
        #expect(t.screen.cursorRow == 2 && t.screen.cursorColumn == 4)
        #expect(t.screen.graphics.placements.isEmpty)
        #expect(
            t.screen.graphics.virtualPlacements == [
                VirtualPlacement(image: 7, placement: 0, columns: 4, rows: 2, layer: 0)
            ]
        )
        #expect(shown(t).isEmpty, "no cell names it yet")
    }

    @Test func `ask's rows of cells draw the whole image, once, scaled to its cells`() {
        var t = terminal()
        virtual(&t, 7, 20, 20, columns: 4, rows: 2)
        t.feed("\(esc)[1;3H" + color(7) + cells(row: 0, count: 4) + "\(esc)[2;3H" + cells(row: 1, count: 4))
        let placements = shown(t)
        #expect(placements.count == 1)
        let placement = placements.first
        #expect(placement?.column == 2 && placement?.columns == 4 && placement?.rows == 2)
        #expect(placement?.width == 40 && placement?.height == 40, "20 pixels scaled into 4 × 2 cells of 10 × 20")
        #expect(
            placement?.sourceX == 0 && placement?.sourceY == 0 && placement?.sourceWidth == 20
                && placement?.sourceHeight == 20
        )
        #expect(placement?.stableLine == t.screen.scrollbackCount && placement?.offsetX == 0 && placement?.offsetY == 0)
    }

    @Test func `a wide image is fitted and centred: the rows above and below it stay empty`() {
        var t = terminal()
        virtual(&t, 7, 40, 20, columns: 4, rows: 4)
        t.feed(color(7) + (0 ..< 4).map { "\(esc)[\($0 + 1);1H" + cells(row: $0, count: 4) }.joined())
        let placement = shown(t).first
        #expect(placement?.width == 40 && placement?.height == 20, "its own size fits 40 × 80 pixels")
        #expect(
            placement?.stableLine == t.screen.scrollbackCount + 1 && placement?.offsetY == 10,
            "30 pixels down: centred"
        )
        #expect(placement?.rows == 3 && placement?.sourceHeight == 20)
    }

    @Test func `marks left out continue the cell before, as kitty reads them`() {
        var t = terminal()
        virtual(&t, 7, 20, 20, columns: 4, rows: 2)
        let bare = String(repeating: "\u{10EEEE}", count: 3)
        t.feed(color(7) + "\u{10EEEE}" + mark(0) + mark(0) + bare + "\(esc)[2;1H" + "\u{10EEEE}" + mark(1) + bare)
        var explicit = terminal()
        virtual(&explicit, 7, 20, 20, columns: 4, rows: 2)
        explicit.feed(color(7) + cells(row: 0, count: 4) + "\(esc)[2;1H" + cells(row: 1, count: 4))
        #expect(shown(t) == shown(explicit) && shown(t).count == 1)
    }

    @Test func `the part drawn stays the same while the image scrolls out of the lines asked for`() {
        var t = terminal()
        virtual(&t, 7, 20, 20, columns: 4, rows: 2)
        t.feed(color(7) + cells(row: 0, count: 4) + "\r\n" + cells(row: 1, count: 4))
        let first = t.screen.scrollbackCount
        #expect(t.screen.placeholderPlacements(lines: first + 1 ..< first + 2) == shown(t))
        t.feed("\(esc)[0m" + String(repeating: "\r\n", count: 5))
        #expect(t.screen.scrollbackCount == first + 1)
        #expect(shown(t) == t.screen.placeholderPlacements(lines: first ..< first + 2), "its first row in the history")
    }

    @Test func `a cell written over breaks the image into the parts its cells still show`() throws {
        var t = terminal()
        virtual(&t, 7, 20, 20, columns: 4, rows: 2)
        t.feed(color(7) + cells(row: 0, count: 4) + "\(esc)[2;1H" + cells(row: 1, count: 4) + "\(esc)[0m\(esc)[1;3Hx")
        let placements = shown(t).sorted { ($0.stableLine, $0.column) < ($1.stableLine, $1.column) }
        try #require(placements.count == 3)
        #expect(placements.map(\.column) == [0, 3, 0] && placements.map(\.columns) == [2, 1, 4])
        #expect(placements[1].sourceX == 15 && placements[1].sourceWidth == 5, "the last quarter of the first row")
        #expect(placements[2].sourceY == 10 && placements[2].sourceHeight == 10)
    }

    @Test
    func `a palette colour names an image, the third mark its highest byte, and a delete takes the virtual placement`()
    {
        var t = terminal()
        virtual(&t, 9, 20, 20, columns: 1, rows: 1)
        t.feed("\(esc)[38;5;9m" + cells(row: 0, count: 1))
        #expect(shown(t).map(\.image) == [9])
        let high = 0x0100_0007
        virtual(&t, high, 20, 20, columns: 1, rows: 1)
        t.feed("\r\n" + color(high) + "\u{10EEEE}" + mark(0) + mark(0) + mark(1))
        #expect(shown(t).map(\.image).sorted() == [9, UInt32(high)])
        t.feed("\(esc)_Ga=d,d=i,i=9,q=2\(esc)\\")
        #expect(shown(t).map(\.image) == [UInt32(high)] && t.screen.graphics.virtualPlacements.count == 1)
    }
}
