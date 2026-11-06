import SunsetCore
import Testing

@testable import SunsetRender

@Suite("CPU renderer: hovered link") struct CPURendererLinkTests {
    private let text =
        "\u{1B}]8;;http://a.example\u{07}ab\u{1B}]8;;\u{07}c\u{1B}]8;;http://b.example\u{07}d\u{1B}]8;;\u{07}"

    private func underline(_ rig: CPURendererRig, column: Int) -> RGB {
        rig.pixel(row: 0, column: column, x: 1, y: metrics.underlineY)
    }

    @Test func `a link is not underlined until it is hovered`() {
        var rig = CPURendererRig()
        rig.frame(text, cursorVisible: false)
        for column in 0 ..< 4 { #expect(underline(rig, column: column) == black, "column \(column)") }
    }

    @Test func `the hovered link, all of its cells and no others, is underlined`() {
        var rig = CPURendererRig()
        rig.frame(text, cursorVisible: false)
        guard let id = rig.terminal.screen.linkID(row: 0, column: 0) else {
            Issue.record("no link under the first cell")
            return
        }
        rig.frame(cursorVisible: false, hoveredLink: id)
        #expect(underline(rig, column: 0) == white && underline(rig, column: 1) == white)
        #expect(underline(rig, column: 2) == black, "plain text between the links")
        #expect(underline(rig, column: 3) == black, "the other link")
    }

    @Test func `moving off the link takes the underline away again`() {
        var rig = CPURendererRig()
        rig.frame(text, cursorVisible: false)
        let before = rig.surface
        rig.frame(cursorVisible: false, hoveredLink: rig.terminal.screen.linkID(row: 0, column: 0) ?? 0)
        #expect(rig.surface.pixels != before.pixels)
        rig.frame(cursorVisible: false, hoveredLink: 0)
        #expect(rig.surface.pixels == before.pixels)
    }

    @Test func `a link that is already underlined keeps its own style`() {
        var rig = CPURendererRig()
        rig.frame("\u{1B}[4:3m\u{1B}]8;;http://a.example\u{07}ab", cursorVisible: false)
        let before = rig.surface
        rig.frame(cursorVisible: false, hoveredLink: rig.terminal.screen.linkID(row: 0, column: 0) ?? 0)
        #expect(rig.surface.pixels == before.pixels)
    }

    @Test func `hover frames equal a fresh renderer's`() {
        var rig = CPURendererRig()
        rig.frame(text, cursorVisible: false)
        let id = rig.terminal.screen.linkID(row: 0, column: 3) ?? 0
        rig.frame(cursorVisible: false, hoveredLink: id)
        var fresh = Surface(width: rig.surface.width, height: rig.surface.height)
        CPURenderer(metrics: metrics, glyphs: BoxGlyphSource())
            .render(rig.terminal.screen, into: &fresh, cursorVisible: false, view: FrameView(hoveredLink: id))
        #expect(fresh.pixels == rig.surface.pixels)
    }
}
