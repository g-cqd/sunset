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
}
