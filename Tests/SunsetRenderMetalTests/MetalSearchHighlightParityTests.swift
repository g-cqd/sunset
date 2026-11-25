import SunsetCore
import SunsetRender
import Testing

@testable import SunsetRenderMetal

/// Verifies that CPU and Metal renderers produce bit-identical pixels when `FrameView.search` highlights both passive
/// and current terminal search matches (T-3 / roadmap 0026).
@Suite("Metal vs CPU search highlight parity")
struct MetalSearchHighlightParityTests {
    @Test func `CPU and Metal renderers produce identical pixels for current and passive search matches`() async throws
    {
        guard var rig = MetalRig(columns: 16, rows: 3) else { return }
        rig.terminal.feed("foo bar foo\r\nbaz foo")
        let result = rig.terminal.screen.search(SearchQuery(text: "foo", isRegex: false, matchCase: true))
        #expect(result.matches.count == 3)

        let view = FrameView(search: SearchHighlight(matches: result.matches, current: 1))
        try await rig.frame(cursorVisible: false, view: view)
        #expect(rig.differences().count == 0)

        // Confirm the highlight actually painted distinct colors for passive (col 0) vs current (col 8) matches.
        let y = rig.metrics.originY + 2
        let passivePixel = rig.cpuSurface.pixels[y * rig.cpuSurface.width + rig.metrics.paddingX + 1]
        let currentPixel =
            rig.cpuSurface.pixels[y * rig.cpuSurface.width + rig.metrics.paddingX + 8 * rig.metrics.cellWidth + 1]
        #expect(passivePixel != currentPixel)
    }
}
