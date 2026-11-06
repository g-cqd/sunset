import SunsetCore
import Testing

@testable import SunsetRender

/// A source that shapes runs: a run containing "->" is one glyph over the whole run (a ligature), any other run is drawn as the box glyphs one by one.
final class RunShapingSource: GlyphSource {
    nonisolated(unsafe) var runs: [String] = []
    nonisolated(unsafe) var singles: [String] = []
    var shapesRuns: Bool { true }

    func glyph(for text: String, bold: Bool, italic: Bool, columns: Int, metrics: RenderMetrics) -> GlyphBitmap? {
        singles.append(text)
        return BoxGlyphSource().glyph(for: text, bold: bold, italic: italic, columns: columns, metrics: metrics)
    }

    func glyph(forRun text: String, bold: Bool, italic: Bool, cells: Int, metrics: RenderMetrics) -> GlyphBitmap? {
        runs.append(text + (bold ? "|b" : ""))
        let width = cells * metrics.cellWidth
        if text.contains("->") {
            return GlyphBitmap(
                width: width - 4,
                height: metrics.cellHeight - 4,
                left: 2,
                top: 2,
                coverage: [UInt8](repeating: 255, count: (width - 4) * (metrics.cellHeight - 4))
            )
        }
        var canvas = [UInt8](repeating: 0, count: width * metrics.cellHeight)
        for (index, _) in text.unicodeScalars.enumerated() {
            for y in 2 ..< metrics.cellHeight - 2 {
                for x in 2 ..< metrics.cellWidth - 2 { canvas[y * width + index * metrics.cellWidth + x] = 255 }
            }
        }
        return GlyphBitmap(width: width, height: metrics.cellHeight, left: 0, top: 0, coverage: canvas)
    }
}
