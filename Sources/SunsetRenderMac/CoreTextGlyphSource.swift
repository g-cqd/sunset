// The platform seam of the renderer on macOS (white paper section 9): glyphs rasterised by CoreText into coverage bitmaps. Nothing else imports CoreText.
internal import CoreGraphics
internal import CoreText
public import SunsetRender

/// Rasterises text with a macOS font (any installed monospaced font; CoreText substitutes fonts for what it lacks: CJK, emoji). `metrics` gives the cell
/// size that font implies.
public final class CoreTextGlyphSource: GlyphSource {
    public let metrics: RenderMetrics
    private let regular: CTFont
    private let bold: CTFont
    private let italic: CTFont
    private let boldItalic: CTFont
    private let baseline: Int

    public init(fontName: String = "Menlo", size: Double = 14) {
        let base = CTFontCreateWithName(fontName as CFString, size, nil)
        regular = base
        bold = CTFontCreateCopyWithSymbolicTraits(base, size, nil, .traitBold, .traitBold) ?? base
        italic = CTFontCreateCopyWithSymbolicTraits(base, size, nil, .traitItalic, .traitItalic) ?? base
        boldItalic =
            CTFontCreateCopyWithSymbolicTraits(base, size, nil, [.traitBold, .traitItalic], [.traitBold, .traitItalic])
            ?? base
        let ascent = CTFontGetAscent(base)
        let descent = CTFontGetDescent(base)
        let leading = CTFontGetLeading(base)
        var advance = CGSize.zero
        var glyph = CTFontGetGlyphWithName(base, "M" as CFString)
        unsafe CTFontGetAdvancesForGlyphs(base, .horizontal, &glyph, &advance, 1)
        let width = max(4, Int(advance.width.rounded()))
        let height = max(8, Int((ascent + descent + leading).rounded(.up)))
        var made = RenderMetrics(cellWidth: width, cellHeight: height)
        baseline = Int(descent.rounded(.up) + (leading / 2).rounded(.down))
        // Decorations by the font's own measurements.
        let underlinePosition = Int(abs(CTFontGetUnderlinePosition(base)).rounded())
        made.underlineY = min(height - 1, height - baseline + max(1, underlinePosition))
        made.lineThickness = max(1, Int(CTFontGetUnderlineThickness(base).rounded()))
        made.strikeY = max(0, height - baseline - Int((CTFontGetXHeight(base) / 2).rounded()))
        made.overlineY = 0
        metrics = made
    }

    public func glyph(for text: String, bold isBold: Bool, italic isItalic: Bool, columns: Int, metrics: RenderMetrics)
        -> GlyphBitmap?
    {
        guard let first = text.unicodeScalars.first, first.value > 0x20 else { return nil }
        let font = isBold ? (isItalic ? boldItalic : bold) : (isItalic ? italic : regular)
        let width = metrics.cellWidth * columns
        let height = metrics.cellHeight
        var coverage = [UInt8](repeating: 0, count: width * height)
        let drawn = coverage.withUnsafeMutableBytes { raw -> Bool in
            guard
                let context = unsafe CGContext(
                    data: raw.baseAddress,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: width,
                    space: CGColorSpaceCreateDeviceGray(),
                    bitmapInfo: CGImageAlphaInfo.none.rawValue
                )
            else { return false }
            context.setShouldAntialias(true)
            context.setShouldSmoothFonts(false)
            context.setFillColor(gray: 1, alpha: 1)
            let attributed = CFAttributedStringCreateMutable(nil, 0)!
            CFAttributedStringReplaceString(attributed, CFRange(location: 0, length: 0), text as CFString)
            CFAttributedStringSetAttribute(
                attributed,
                CFRange(location: 0, length: CFAttributedStringGetLength(attributed)),
                kCTFontAttributeName,
                font
            )
            // Without this the text is black whatever the context's fill colour says.
            CFAttributedStringSetAttribute(
                attributed,
                CFRange(location: 0, length: CFAttributedStringGetLength(attributed)),
                kCTForegroundColorFromContextAttributeName,
                kCFBooleanTrue
            )
            let line = CTLineCreateWithAttributedString(attributed)
            // A line wider than its cells (a fallback font's wide glyph) is not squeezed; the renderer clips it to the cells.
            context.textPosition = CGPoint(x: 0, y: CGFloat(baseline))
            CTLineDraw(line, context)
            return true
        }
        guard drawn, coverage.contains(where: { $0 != 0 }) else { return nil }
        return GlyphBitmap(width: width, height: height, left: 0, top: 0, coverage: coverage)
    }
}
