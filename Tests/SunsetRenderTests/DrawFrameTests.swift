import SunsetCore
import Testing

@testable import SunsetRender

/// The draw list is what a GPU renderer replays: replaying it on the CPU must give exactly the pixels the CPU renderer draws itself.
@Suite("Draw list (recorded frames)") struct DrawFrameTests {
    private func rig() -> CPURendererRig { CPURendererRig(20, 6) }

    private func recorded(_ rig: CPURendererRig, view: FrameView = FrameView(), cursorVisible: Bool = true) -> DrawFrame
    {
        rig.renderer.record(
            rig.terminal.screen,
            width: rig.surface.width,
            height: rig.surface.height,
            cursorVisible: cursorVisible,
            view: view
        )
    }

    @Test func `replaying a full frame gives the pixels the renderer draws`() {
        var live = rig()
        let text =
            "\u{1B}[1mbold\u{1B}[0m \u{1B}[4munder\u{1B}[0m \u{1B}[7minv\u{1B}[0m\r\n\u{1B}[31;42mcolour\u{1B}[0m ─│┌┐\r\n\u{1B}[9mstrike\u{1B}[53m over\u{1B}[0m"
        live.terminal.feed(text)
        let recorder = rig()
        var mirror = recorder
        mirror.terminal.feed(text)
        let frame = recorded(mirror)
        var replayed = Surface(width: live.surface.width, height: live.surface.height)
        frame.replay(onto: &replayed)
        live.frame()
        #expect(replayed.pixels == live.surface.pixels)
        #expect(frame.ops.count > 20 && frame.changedPixelRows == 0 ... live.surface.height - 1)
    }

    @Test func `recording writes no pixels`() {
        var live = rig()
        live.terminal.feed("hello")
        let blank = live.surface.pixels
        _ = recorded(live)
        #expect(live.surface.pixels == blank)
    }

    @Test func `a second recorded frame holds only the rows that changed`() {
        var live = rig()
        live.terminal.feed("one\r\ntwo\r\nthree")
        let first = recorded(live)
        live.terminal.clearDirty()
        live.terminal.feed("\u{1B}[3;1Hxyz")
        let second = recorded(live)
        #expect(first.ops.count > second.ops.count)
        #expect(second.changedPixelRows != nil && second.changedPixelRows != first.changedPixelRows)
        live.terminal.clearDirty()
        #expect(recorded(live).ops.isEmpty && recorded(live).changedPixelRows == nil)
    }

    @Test func `a translucent frame says so, and replays like the renderer draws it`() {
        let text = "\u{1B}]11;#204060\u{7}text \u{1B}[41mred\u{1B}[0m"
        var live = rig()
        live.backgroundAlpha = 120
        live.terminal.feed(text)
        var mirror = rig()
        mirror.terminal.feed(text)
        let frame = mirror.renderer.record(
            mirror.terminal.screen,
            width: mirror.surface.width,
            height: mirror.surface.height,
            view: FrameView(backgroundAlpha: 120)
        )
        #expect(frame.translucent)
        var replayed = Surface(width: live.surface.width, height: live.surface.height)
        frame.replay(onto: &replayed)
        live.frame()
        #expect(replayed.pixels == live.surface.pixels)
    }

    @Test func `glyphs are named by their place in the frame's glyph table, the same place in every frame`() throws {
        var live = rig()
        live.terminal.feed("aba")
        let first = recorded(live, cursorVisible: false)
        live.terminal.clearDirty()
        live.terminal.feed("\u{1B}[2;1Hba")
        let second = recorded(live, cursorVisible: false)
        let glyphs = first.ops.filter { $0.glyph != 0 }
        #expect(glyphs.count == 3)
        // The two a's are one glyph, the b another.
        #expect(glyphs[0].glyph == glyphs[2].glyph && glyphs[0].glyph != glyphs[1].glyph)
        for op in first.ops where op.glyph != 0 { #expect(Int(op.glyph) <= first.glyphs.count) }
        let again = second.ops.filter { $0.glyph != 0 }
        #expect(again.map(\.glyph) == [glyphs[1].glyph, glyphs[0].glyph])
        let a = try #require(first.glyph(of: glyphs[0]))
        let sameA = try #require(second.glyph(of: again[1]))
        #expect(a === sameA)
        #expect(first.glyphGeneration == second.glyphGeneration)
    }

    @Test func `a full glyph table starts again between frames, under a new generation`() {
        var live = rig()
        live.renderer.glyphTableLimit = 2
        live.terminal.feed("abc")
        let first = recorded(live, cursorVisible: false)
        live.terminal.clearDirty()
        live.terminal.feed("\u{1B}[2;1Hd")
        let second = recorded(live, cursorVisible: false)
        #expect(second.glyphGeneration != first.glyphGeneration)
        #expect(second.glyphs.count < first.glyphs.count)
        for op in second.ops where op.glyph != 0 { #expect(Int(op.glyph) <= second.glyphs.count) }
        var replayed = Surface(width: live.surface.width, height: live.surface.height)
        first.replay(onto: &replayed)
        second.replay(onto: &replayed)
        var drawn = rig()
        drawn.frame("abc", cursorVisible: false)
        drawn.frame("\u{1B}[2;1Hd", cursorVisible: false)
        #expect(replayed.pixels == drawn.surface.pixels)
    }

    @Test func `two renderers never share a glyph generation`() {
        let one = rig()
        let other = rig()
        #expect(recorded(one).glyphGeneration != recorded(other).glyphGeneration)
        #expect(recorded(one).glyphGeneration != 0)
    }
}
