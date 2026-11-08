import Foundation
import SunsetConfig
import SunsetRender
import SunsetRenderMac
import SunsetRenderMetal

extension TerminalModel {
    /// The GPU renderer failed (the device was lost, a command did not complete): this window draws with the CPU renderer from now on, and says so in the log.
    /// The last frame stays on screen until the CPU renderer's first one replaces it.
    func fallBackToCPU() {
        FileHandle.standardError.write(Data("sunset: the GPU renderer failed, drawing on the CPU\n".utf8))
        rendererChoice = .cpu
        makeRenderer()
        requestFrame()
    }

    /// Makes the renderer for the font, the padding and the scale as they are now: the Metal one when it is asked for (`gpu`, or `auto` when the GPU
    /// renders as well as the CPU does) and the machine has a device, else the CPU one.
    func makeRenderer() {
        let glyphs = CoreTextGlyphSource(fontName: font.name, size: font.size * scale, features: font.features)
        var metrics = glyphs.metrics
        metrics.paddingX = paddingPixels
        metrics.paddingY = paddingPixels
        metrics.topInset = Int((topInsetPoints * scale).rounded())
        if rendererChoice != .cpu,
            let gpu = MetalSurfaceRenderer(metrics: metrics, glyphs: glyphs, ligatures: font.ligatures)
        {
            renderer = gpu
        } else {
            renderer = CPUSurfaceRenderer(metrics: metrics, glyphs: glyphs, ligatures: font.ligatures)
        }
    }
}
