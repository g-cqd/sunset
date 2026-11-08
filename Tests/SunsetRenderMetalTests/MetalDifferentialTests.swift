import SunsetCore
import Testing

@testable import SunsetRender
@testable import SunsetRenderMetal

/// The Metal renderer replays the CPU renderer's draw list; the CPU renderer is the oracle (ADR-0024), so the two must agree pixel for pixel.
@Suite("Metal renderer against the CPU oracle", .serialized) struct MetalDifferentialTests {
    private let esc = "\u{1B}"

    @Test func `the comparison can fail: a pixel changed on one side only is found, and the frames are not blank`()
        async throws
    {
        var rig = try #require(MetalRig(), "a Metal device")
        try await rig.frame("hello \(esc)[41mred\(esc)[0m")
        #expect(rig.differences().count == 0)
        let background = rig.cpuSurface.pixels[0]
        #expect(rig.cpuSurface.pixels.contains { $0 != background }, "something was drawn")
        let extra = DrawFrame(
            width: rig.cpuSurface.width,
            height: rig.cpuSurface.height,
            ops: [.fill(x: 5, y: 5, width: 3, height: 2, color: 0xFF12_3456)],
            translucent: false,
            changedPixelRows: 5 ... 6
        )
        try await rig.metal.apply(extra, to: rig.target)
        #expect(rig.differences().count == 6)
    }

    @Test func `backgrounds, colours, the cursor and decorations are exact`() async throws {
        var rig = try #require(MetalRig(), "a Metal device")
        try await rig.frame(
            "\(esc)[41mred\(esc)[0m \(esc)[48;2;10;200;90mgreen\(esc)[0m \(esc)[4munder\(esc)[0m \(esc)[9mstrike\(esc)[0m\r\n"
                + "\(esc)[4:3mcurly\(esc)[4:4mdotted\(esc)[4:5mdashed\(esc)[0m \(esc)[53mover\(esc)[0m \(esc)[7minv\(esc)[0m"
        )
        let difference = rig.differences()
        #expect(difference.count == 0, "\(difference.count) pixels differ, by up to \(difference.largest)")
    }

    @Test func `box drawing glyphs are exact, with the coverage blended as the CPU does`() async throws {
        var rig = try #require(MetalRig(), "a Metal device")
        try await rig.frame("┌──┬──┐\r\n│ ╭╮│  │\r\n├──┼──┤\r\n▀▄█▌▐░▒▓\r\n⠁⠃⠇⡇⣿")
        let difference = rig.differences()
        #expect(difference.count == 0, "\(difference.count) pixels differ, by up to \(difference.largest)")
    }

    @Test func `a bar and an underline cursor, and a selection, are exact`() async throws {
        var rig = try #require(MetalRig(), "a Metal device")
        for style in [3, 5, 1] {
            try await rig.frame("\(esc)[\(style) qabc def")
            #expect(rig.differences().count == 0, "cursor style \(style)")
        }
        let selection = Selection(anchor: .init(line: 0, column: 1), head: .init(line: 1, column: 4))
        try await rig.frame("", view: FrameView(selection: selection))
        #expect(rig.differences().count == 0, "selection")
    }

    @Test func `later frames draw only what changed and still agree`() async throws {
        var rig = try #require(MetalRig(), "a Metal device")
        try await rig.frame("one\r\ntwo\r\nthree\r\nfour")
        try await rig.frame("\(esc)[2;1H\(esc)[31mTWO")
        try await rig.frame("\(esc)[H\(esc)[Jfresh start \(esc)[1mbold\(esc)[0m")
        #expect(rig.differences().count == 0)
    }

    @Test func `a translucent window agrees too, text blended over any alpha`() async throws {
        var rig = try #require(MetalRig(), "a Metal device")
        rig.alpha = 110
        try await rig.frame("\(esc)]11;#204060\u{7}text \(esc)[41mred\(esc)[0m ┌─┐\r\n\(esc)[4munder\(esc)[0m")
        let difference = rig.differences()
        #expect(difference.count == 0, "\(difference.count) pixels differ, by up to \(difference.largest)")
    }

    @Test func `glyph numbers of a new generation are uploaded again, not taken for the old glyphs`() async throws {
        var rig = try #require(MetalRig(), "a Metal device")
        // A table of two glyphs starts again at the third frame: glyph 1 is then "c", which the atlas held as "a".
        rig.gpuSide.glyphTableLimit = 2
        try await rig.frame("ab", cursorVisible: false)
        try await rig.frame("\(esc)[2;1Hcd", cursorVisible: false)
        try await rig.frame("\(esc)[3;1Hef", cursorVisible: false)
        #expect(rig.differences().count == 0)
    }
}
