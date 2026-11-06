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

    public let fullName: String

    /// `features` are applied to every style of the font. Ligatures and contextual alternates (`liga`, `clig`, `calt`) are the font's default; pass
    /// `ligatures: false` (or `FontFeature("liga", 0)` and friends) to turn them off.
    public init(fontName: String = "Menlo", size: Double = 14, features: [FontFeature] = [], ligatures: Bool = true) {
        var settings = features
        // Giving CoreText any feature list replaces the font's own defaults for those it names only, but to be explicit (and to be able to turn them
        // off) the ligature features are always stated.
        for tag in ["liga", "clig", "calt"] where !settings.contains(where: { $0.tag == tag }) {
            settings.append(FontFeature(tag, ligatures ? 1 : 0))
        }
        func featured(_ font: CTFont) -> CTFont {
            let list = settings.map { feature -> [CFString: Any] in
                [
                    kCTFontOpenTypeFeatureTag: feature.tag as CFString,
                    kCTFontOpenTypeFeatureValue: feature.value as CFNumber
                ]
            }
            let descriptor = CTFontDescriptorCreateCopyWithAttributes(
                CTFontCopyFontDescriptor(font),
                [kCTFontFeatureSettingsAttribute: list] as CFDictionary
            )
            return CTFontCreateWithFontDescriptor(descriptor, CTFontGetSize(font), nil)
        }
        let plain = CTFontCreateWithName(fontName as CFString, size, nil)
        let base = featured(plain)
        fullName = CTFontCopyFullName(base) as String
        regular = base
        bold = featured(CTFontCreateCopyWithSymbolicTraits(plain, size, nil, .traitBold, .traitBold) ?? plain)
        italic = featured(CTFontCreateCopyWithSymbolicTraits(plain, size, nil, .traitItalic, .traitItalic) ?? plain)
        boldItalic = featured(
            CTFontCreateCopyWithSymbolicTraits(plain, size, nil, [.traitBold, .traitItalic], [.traitBold, .traitItalic])
                ?? plain
        )
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

    public var shapesRuns: Bool { true }

    public func glyph(for text: String, bold isBold: Bool, italic isItalic: Bool, columns: Int, metrics: RenderMetrics)
        -> GlyphBitmap?
    {
        rasterise(text, bold: isBold, italic: isItalic, cells: columns, metrics: metrics)
    }

    public func glyph(forRun text: String, bold isBold: Bool, italic isItalic: Bool, cells: Int, metrics: RenderMetrics)
        -> GlyphBitmap?
    {
        rasterise(text, bold: isBold, italic: isItalic, cells: cells, metrics: metrics)
    }

    /// Shapes `text` as one line (so ligatures and contextual alternates apply) and draws it into a bitmap `cells` cells wide.
    private func rasterise(_ text: String, bold isBold: Bool, italic isItalic: Bool, cells: Int, metrics: RenderMetrics)
        -> GlyphBitmap?
    {
        guard let first = text.unicodeScalars.first, first.value > 0x20 else { return nil }
        let font = isBold ? (isItalic ? boldItalic : bold) : (isItalic ? italic : regular)
        let width = metrics.cellWidth * cells
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
            guard let attributed = CFAttributedStringCreateMutable(nil, 0) else { return false }
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
            drawGlyphs(of: line, text: text, into: context, cellWidth: metrics.cellWidth)
            return true
        }
        guard drawn, coverage.contains(where: { $0 != 0 }) else { return nil }
        return GlyphBitmap(width: width, height: height, left: 0, top: 0, coverage: coverage)
    }

    /// Draws the shaped glyphs of `line` on the cell grid: a glyph goes at the left of the cell its first character is in, whatever the font's own advance
    /// (which is rarely a whole number of pixels), and a ligature, being one glyph for several characters, spans their cells. Fallback fonts keep their
    /// own run fonts.
    private func drawGlyphs(of line: CTLine, text: String, into context: CGContext, cellWidth: Int) {
        // The cell of each UTF-16 unit of the text (a character outside the BMP is two units in one cell).
        var cellOfUnit: [Int] = []
        for (cell, scalar) in text.unicodeScalars.enumerated() {
            cellOfUnit.append(cell)
            if scalar.value > 0xFFFF { cellOfUnit.append(cell) }
        }
        let runs = (CTLineGetGlyphRuns(line) as? [CTRun]) ?? []
        for run in runs {
            let count = CTRunGetGlyphCount(run)
            guard count > 0 else { continue }
            var glyphs = [CGGlyph](repeating: 0, count: count)
            var indices = [CFIndex](repeating: 0, count: count)
            unsafe CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &glyphs)
            unsafe CTRunGetStringIndices(run, CFRange(location: 0, length: 0), &indices)
            // The run's own font (a fallback font for a character the main one lacks), read from the run's attributes.
            let attributes = CTRunGetAttributes(run)
            guard
                let raw = unsafe CFDictionaryGetValue(
                    attributes,
                    Unmanaged.passUnretained(kCTFontAttributeName).toOpaque()
                )
            else {
                continue
            }
            let font = unsafe Unmanaged<CTFont>.fromOpaque(raw).takeUnretainedValue()
            for index in 0 ..< count {
                let unit = min(max(0, indices[index]), cellOfUnit.count - 1)
                var position = CGPoint(x: CGFloat(cellOfUnit[unit] * cellWidth), y: CGFloat(baseline))
                unsafe CTFontDrawGlyphs(font, &glyphs[index], &position, 1, context)
            }
        }
    }
}
