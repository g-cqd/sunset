import IOSurface
import SunsetCore
import SunsetRender
import SunsetRenderMac
import Testing

@testable import SunsetRenderMetal

/// The two `IOSurfaceRenderer`s, driven alike, must leave the same pixels in the surfaces a window shows, through the three-surface rotation and its
/// missed-rows bookkeeping.
@Suite("Metal and CPU surface renderers", .serialized) struct MetalSurfaceRendererTests {
    private let esc = "\u{1B}"

    private func pixels(_ surface: IOSurface) -> [UInt8] {
        surface.lock(options: .readOnly, seed: nil)
        defer { surface.unlock(options: .readOnly, seed: nil) }
        var bytes: [UInt8] = []
        for row in 0 ..< surface.height {
            let start = surface.baseAddress + row * surface.bytesPerRow
            bytes.append(
                contentsOf: UnsafeBufferPointer(
                    start: start.assumingMemoryBound(to: UInt8.self),
                    count: surface.width * 4
                )
            )
        }
        return bytes
    }

    private func renderers() throws -> (cpu: CPUSurfaceRenderer, gpu: MetalSurfaceRenderer, metrics: RenderMetrics) {
        let source = CoreTextGlyphSource(fontName: "Menlo", size: 28, features: [])
        var metrics = source.metrics
        metrics.paddingX = 4
        metrics.paddingY = 4
        let gpu = try #require(
            MetalSurfaceRenderer(metrics: metrics, glyphs: source, ligatures: false),
            "a Metal device"
        )
        return (CPUSurfaceRenderer(metrics: metrics, glyphs: source, ligatures: false), gpu, metrics)
    }

    @Test func `many frames through the rotation leave the same pixels, and an unchanged frame changes nothing`()
        async throws
    {
        let (cpu, gpu, _) = try renderers()
        var terminal = Terminal(columns: 30, rows: 8)
        let view = FrameView(extraPixels: (5, 3))
        for step in 0 ..< 8 {
            terminal.feed("\(esc)[\(step % 7 + 1);1Hrow \(step) \(esc)[3\(step % 7 + 1)mcolour\(esc)[0m ┌─┐ 日本\r\n")
            let first = await cpu.present(terminal.screen, cursorVisible: true, textBlinkVisible: true, view: view)
            let second = await gpu.present(terminal.screen, cursorVisible: true, textBlinkVisible: true, view: view)
            terminal.clearDirty()
            #expect(first && second, "step \(step) draws")
            let a = try #require(cpu.latest)
            let b = try #require(gpu.latest)
            #expect(pixels(a) == pixels(b), "step \(step)")
            #expect(Set(pixels(b)).count > 8, "step \(step) is not blank")
        }
        let still = await gpu.present(terminal.screen, cursorVisible: true, textBlinkVisible: true, view: view)
        #expect(!still, "nothing changed")
        #expect(gpu.backend == .gpu && cpu.backend == .cpu)
    }

    @Test func `a resize starts again and still agrees`() async throws {
        let (cpu, gpu, _) = try renderers()
        var terminal = Terminal(columns: 30, rows: 8)
        terminal.feed("hello \(esc)[44mblue\(esc)[0m")
        _ = await cpu.present(terminal.screen, cursorVisible: true, textBlinkVisible: true, view: FrameView())
        _ = await gpu.present(terminal.screen, cursorVisible: true, textBlinkVisible: true, view: FrameView())
        terminal.resize(columns: 44, rows: 5)
        terminal.feed("\r\nafter the resize")
        _ = await cpu.present(terminal.screen, cursorVisible: false, textBlinkVisible: true, view: FrameView())
        _ = await gpu.present(terminal.screen, cursorVisible: false, textBlinkVisible: true, view: FrameView())
        let a = try #require(cpu.latest)
        let b = try #require(gpu.latest)
        #expect(a.width == b.width && a.height == b.height && pixels(a) == pixels(b))
    }

    @Test func `presents that arrive while a frame is drawn wait their turn`() async throws {
        let (cpu, gpu, _) = try renderers()
        var terminal = Terminal(columns: 30, rows: 16)
        func row(_ row: Int) -> String { "\(esc)[\(row + 1);1Hrow \(row) \(esc)[3\(row % 7 + 1)mcolour\(esc)[0m ┌─┐" }
        for index in 0 ..< 16 { terminal.feed(row(index)) }
        _ = await cpu.present(terminal.screen, cursorVisible: false, textBlinkVisible: true, view: FrameView())
        _ = await gpu.present(terminal.screen, cursorVisible: false, textBlinkVisible: true, view: FrameView())
        terminal.clearDirty()
        // Each snapshot rewrites one row with what it held: the same picture, a different changed row. The tasks reach the actor in any order (a stale
        // snapshot would redraw rows wrongly in any renderer, so the order is the caller's: the app has one frame in flight); what is tested is that a
        // present arriving while another awaits the GPU neither breaks the compositor (it asserts one frame at a time) nor the surfaces' missed rows.
        var snapshots: [Screen] = []
        for index in 0 ..< 16 {
            terminal.feed(row(index))
            snapshots.append(terminal.screen)
            terminal.clearDirty()
        }
        await withTaskGroup { group in
            for snapshot in snapshots {
                group.addTask {
                    _ = await gpu.present(snapshot, cursorVisible: false, textBlinkVisible: true, view: FrameView())
                }
            }
        }
        let a = try #require(cpu.latest)
        let b = try #require(gpu.latest)
        #expect(pixels(a) == pixels(b))
    }

    @Test func `the first surface exists only after a frame`() async throws {
        let (_, gpu, _) = try renderers()
        #expect(gpu.latest == nil)
    }
}
