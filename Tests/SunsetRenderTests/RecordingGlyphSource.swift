import SunsetCore
import Testing

@testable import SunsetRender

/// Records what the renderer asks for.
final class RecordingGlyphSource: GlyphSource {
    nonisolated(unsafe) var requests: [String] = []
    func glyph(for text: String, bold: Bool, italic: Bool, columns: Int, metrics: RenderMetrics) -> GlyphBitmap? {
        requests.append("\(text)|\(bold ? "b" : "")\(italic ? "i" : "")|\(columns)")
        return BoxGlyphSource().glyph(for: text, bold: bold, italic: italic, columns: columns, metrics: metrics)
    }
}
