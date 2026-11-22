import AemiKernel
import Testing

@testable import SunsetCore

/// The kitty graphics protocol, first part (roadmap 0010, ADR-0117): images sent in the escape itself (raw RGB, RGBA, or
/// PNG kept encoded with its size read), in chunks; placed at the cursor over the cells their pixels cover, the cursor
/// moved after them; deleted; queried; answered as kitty answers. What reads outside the stream (a file, a temporary file,
/// shared memory) is refused; images are kept within a quota.
@Suite("kitty graphics") struct KittyGraphicsTests {
    private func terminal() -> Terminal {
        var t = Terminal(columns: 20, rows: 6)
        t.setCellPixelSize(width: 10, height: 20)
        return t
    }

    private func replies(_ t: inout Terminal) -> String {
        String(decoding: t.takeReplies(), as: UTF8.self)
    }

    /// `pixels` RGBA bytes for a `width` × `height` image, base64.
    private func rgba(_ width: Int, _ height: Int) -> String {
        let bytes = [UInt8](repeating: 0x7F, count: width * height * 4)
        return Base64.encodedString(bytes)
    }

    @Test func `a query is answered OK for what is supported, and stores nothing`() {
        var t = terminal()
        t.feed("\(esc)_Gi=31,s=1,v=1,a=q,t=d,f=24;AAAA\(esc)\\")
        #expect(replies(&t) == "\(esc)_Gi=31;OK\(esc)\\")
        #expect(t.screen.graphics.images.isEmpty)
    }

    @Test func `transmitted, then answered; q=1 keeps quiet on success, q=2 always`() {
        var t = terminal()
        t.feed("\(esc)_Ga=t,i=1,f=32,s=2,v=2;\(rgba(2, 2))\(esc)\\")
        #expect(replies(&t) == "\(esc)_Gi=1;OK\(esc)\\")
        #expect(t.screen.graphics.images[1]?.width == 2 && t.screen.graphics.images[1]?.pixels.count == 16)
        t.feed("\(esc)_Ga=t,i=2,q=1,f=32,s=1,v=1;\(rgba(1, 1))\(esc)\\")
        #expect(replies(&t).isEmpty)
        t.feed("\(esc)_Ga=t,i=3,q=2,f=32,s=9,v=9;\(rgba(1, 1))\(esc)\\")
        #expect(replies(&t).isEmpty, "a wrong size is an error, kept quiet by q=2")
        t.feed("\(esc)_Ga=t,i=4,f=32,s=9,v=9;\(rgba(1, 1))\(esc)\\")
        #expect(replies(&t).hasPrefix("\(esc)_Gi=4;ENODATA"))
    }

    @Test func `sent in chunks, put together`() {
        var t = terminal()
        let data = rgba(4, 4)
        let half = data.index(data.startIndex, offsetBy: 32)
        t.feed("\(esc)_Ga=t,i=7,f=32,s=4,v=4,m=1;\(data[..<half])\(esc)\\")
        #expect(replies(&t).isEmpty && t.screen.graphics.images[7] == nil, "not yet whole")
        t.feed("\(esc)_Gm=0;\(data[half...])\(esc)\\")
        #expect(t.screen.graphics.images[7]?.pixels.count == 64)
    }

    @Test func `displayed at the cursor over the cells it covers; the cursor moved after it, unless C=1`() {
        var t = terminal()
        t.feed("ab\(esc)_Ga=T,i=5,f=32,s=25,v=30;\(rgba(25, 30))\(esc)\\")
        let placed = t.screen.graphics.placements.first
        #expect(placed?.image == 5 && placed?.column == 2 && placed?.columns == 3 && placed?.rows == 2)
        #expect(t.screen.cursorRow == 1 && t.screen.cursorColumn == 5)
        t.feed("\(esc)_Ga=p,i=5,c=4,r=1,C=1\(esc)\\")
        #expect(t.screen.graphics.placements.last?.columns == 4 && t.screen.cursorColumn == 5)
    }

    @Test func `deleted: one image, or all`() {
        var t = terminal()
        t.feed(
            "\(esc)_Ga=T,i=1,q=2,f=32,s=1,v=1;\(rgba(1, 1))\(esc)\\\(esc)_Ga=T,i=2,q=2,f=32,s=1,v=1;\(rgba(1, 1))\(esc)\\"
        )
        t.feed("\(esc)_Ga=d,d=I,i=1\(esc)\\")
        #expect(t.screen.graphics.images.keys.sorted() == [2] && t.screen.graphics.placements.map(\.image) == [2])
        t.feed("\(esc)_Ga=d,d=A\(esc)\\")
        #expect(t.screen.graphics.images.isEmpty && t.screen.graphics.placements.isEmpty)
    }

    @Test func `a PNG is kept encoded, its size read from its header`() {
        var t = terminal()
        // An 8 × 3 PNG's signature and IHDR (the pixels are the renderer's to decode).
        let png: [UInt8] = [
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 13, 0x49, 0x48, 0x44, 0x52,
            0, 0, 0, 8, 0, 0, 0, 3, 8, 6, 0, 0, 0, 0, 0, 0, 0
        ]
        t.feed("\(esc)_Ga=t,i=9,f=100;\(Base64.encodedString(png))\(esc)\\")
        #expect(t.screen.graphics.images[9]?.width == 8 && t.screen.graphics.images[9]?.height == 3)
        #expect(t.screen.graphics.images[9]?.format == .png)
    }

    @Test func `a file, a temporary file or shared memory is refused, as compression for now`() {
        var t = terminal()
        for medium in ["f", "t", "s"] {
            t.feed("\(esc)_Ga=t,i=1,t=\(medium),f=100;L3RtcC94\(esc)\\")
            #expect(replies(&t).hasPrefix("\(esc)_Gi=1;EPERM"), "t=\(medium)")
        }
        t.feed("\(esc)_Ga=t,i=1,o=z,f=32,s=1,v=1;AAAA\(esc)\\")
        #expect(replies(&t).hasPrefix("\(esc)_Gi=1;EINVAL"))
        #expect(t.screen.graphics.images.isEmpty)
    }

    @Test func `the quota: the oldest images go first when a new one would not fit`() {
        var t = terminal()
        t.setGraphicsQuota(bytes: 40)
        for id in 1 ... 3 {
            t.feed("\(esc)_Ga=t,i=\(id),q=2,f=32,s=2,v=2;\(rgba(2, 2))\(esc)\\")
        }
        #expect(t.screen.graphics.images.keys.sorted() == [2, 3] && t.screen.graphics.bytes <= 40)
    }

    @Test
    func `a placement moves with its text as the screen scrolls; a full reset takes the images, not the cell size`() {
        var t = terminal()
        t.feed("\(esc)_Ga=T,i=1,q=2,f=32,s=10,v=20;\(rgba(10, 20))\(esc)\\")
        let line = try? #require(t.screen.graphics.placements.first?.stableLine)
        t.feed(String(repeating: "\r\n", count: 8))
        #expect(t.screen.graphics.placements.first?.stableLine == line, "its line, wherever it is now")
        #expect(t.screen.absoluteLine(ofStable: line ?? 0) == 0, "the first line of the history")
        t.feed("\(esc)c")
        #expect(t.screen.graphics.images.isEmpty && t.screen.graphics.placements.isEmpty)
        t.feed("\(esc)_Ga=T,i=2,q=2,f=32,s=25,v=30;\(rgba(25, 30))\(esc)\\")
        #expect(t.screen.graphics.placements.first?.columns == 3, "10-pixel cells still")
    }

    @Test func `what does not read is ignored: no image, no reply, nothing kept`() {
        var t = terminal()
        for command in [
            "G", "Ga", "Ga=", "Gi=99999999999,a=t", "Ga=t,i=1,f=32,s=1,v=1;!!!!", "Ga=t,i=1,f=7,s=1,v=1;AAAA",
            "Ga=t,i=1,f=32,s=20000,v=1;AAAA", "Ga=p,i=404", "Xsomething else"
        ] {
            t.feed("\(esc)_\(command)\(esc)\\")
        }
        #expect(
            t.screen.graphics.images.isEmpty && t.screen.graphics.placements.isEmpty && t.screen.graphics.bytes == 0
        )
        let answers = replies(&t)
        #expect(!answers.contains("OK"), "nothing done, nothing said done")
    }

    @Test func `the text area and a cell in pixels are told (CSI 14 t, 16 t), as image tools ask`() {
        var t = terminal()
        t.feed("\(esc)[14t\(esc)[16t")
        #expect(replies(&t) == "\(esc)[4;120;200t\(esc)[6;20;10t")
    }

    @Test func `its size in pixels: its own, stretched over c and r, or scaled to one of them keeping its proportions`()
    {
        var t = terminal()
        let image = rgba(20, 10)
        for (options, expected) in [
            ("", [2, 1, 20, 10]), ("c=4,r=3,", [4, 3, 40, 60]), ("c=4,", [4, 1, 40, 20]), ("r=2,", [8, 2, 80, 40])
        ] {
            t.feed("\(esc)_Ga=T,q=2,C=1,f=32,i=1,s=20,v=10,\(options);\(image)\(esc)\\")
            let placed = t.screen.graphics.placements.last
            #expect(placed.map { [$0.columns, $0.rows, $0.width, $0.height] } == expected, "\(options)")
        }
    }
}
