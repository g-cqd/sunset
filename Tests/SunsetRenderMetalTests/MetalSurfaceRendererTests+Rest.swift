import IOSurface
import SunsetCore
import SunsetRender
import SunsetRenderMac
import Testing

@testable import SunsetRenderMetal

/// A window that has gone quiet, or is not shown, keeps the surface it shows and no other (the review of 2026-11-15, 3.2;
/// owner note n14): a surface is the window's size in pixels, four bytes each.
extension MetalSurfaceRendererTests {
    /// Draws `text` with both renderers; the GPU's surface, checked against the CPU's.
    func frame(
        _ text: String,
        _ terminal: inout Terminal,
        cpu: CPUSurfaceRenderer,
        gpu: MetalSurfaceRenderer
    ) async throws -> IOSurface {
        terminal.feed(text)
        _ = await cpu.present(terminal.screen, cursorVisible: true, textBlinkVisible: true, view: FrameView())
        _ = await gpu.present(terminal.screen, cursorVisible: true, textBlinkVisible: true, view: FrameView())
        terminal.clearDirty()
        let surface = try #require(gpu.latest)
        #expect(try pixels(surface) == pixels(#require(cpu.latest)), "after \(text.debugDescription)")
        return surface
    }

    @Test func `at rest a window keeps the surface it shows, and draws the next frame right`() async throws {
        let (cpu, gpu, _) = try renderers()
        var terminal = Terminal(columns: 20, rows: 4)
        var held: [IOSurface] = []
        for text in ["one\r\n", "two\r\n"] {
            let surface = try await frame(text, &terminal, cpu: cpu, gpu: gpu)
            surface.incrementUseCount()
            held.append(surface)
        }
        let shown = try await frame("three\r\n", &terminal, cpu: cpu, gpu: gpu)
        for surface in held { surface.decrementUseCount() }
        #expect(await gpu.frameBufferCount == 3, "the burst made a third")

        #expect(await gpu.rest(), "everything but the one shown was let go")
        #expect(await gpu.frameBufferCount == 1)
        #expect(gpu.latest === shown, "the one the window shows is kept")
        let before = pixels(shown)

        let next = try await frame("four\r\n", &terminal, cpu: cpu, gpu: gpu)
        #expect(next !== shown, "the surface on screen is not written")
        #expect(pixels(shown) == before)
        #expect(await gpu.frameBufferCount == 2)
        _ = try await frame("\u{1B}[2J\u{1B}[Hfive", &terminal, cpu: cpu, gpu: gpu)
        #expect(await gpu.frameBufferCount == 2, "two again while frames come")
    }

    @Test func `a surface the window server still holds is not let go at rest`() async throws {
        let (cpu, gpu, _) = try renderers()
        var terminal = Terminal(columns: 20, rows: 4)
        let first = try await frame("one\r\n", &terminal, cpu: cpu, gpu: gpu)
        first.incrementUseCount()
        defer { first.decrementUseCount() }
        _ = try await frame("two\r\n", &terminal, cpu: cpu, gpu: gpu)
        #expect(await gpu.rest() == false, "it says so, to be asked again")
        #expect(await gpu.frameBufferCount == 2, "the one held, and the one shown")
        _ = try await frame("three\r\n", &terminal, cpu: cpu, gpu: gpu)
    }

    @Test func `resting before any frame, twice, or on the CPU renderer does nothing`() async throws {
        let (cpu, gpu, _) = try renderers()
        #expect(await gpu.rest())
        #expect(await cpu.rest())
        var terminal = Terminal(columns: 20, rows: 4)
        _ = try await frame("one\r\n", &terminal, cpu: cpu, gpu: gpu)
        #expect(await gpu.rest())
        #expect(await gpu.rest())
        #expect(await gpu.frameBufferCount == 1)
        _ = try await frame("two\r\n", &terminal, cpu: cpu, gpu: gpu)
    }
}
