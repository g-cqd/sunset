/// Optional per-style font families, ordered fallback families, and variable font axes passed to
/// `CoreTextGlyphSource` (T-7 / t182).
public struct FontAppearance: Sendable, Equatable {
    /// Override family/PostScript names for specific styles (nil falls back to symbolic trait synthesis on the base font).
    public var boldName: String?
    public var italicName: String?
    public var boldItalicName: String?
    /// Ordered fallback font families consulted before CoreText's default system cascade list.
    public var fallbackNames: [String]
    /// OpenType variation axis values (`wght`, `wdth`, `opsz`, `slnt`, …) for the regular face; the bold and italic
    /// faces keep their own (as Ghostty's `font-variation`).
    public var variations: [FontVariationAxis]

    public init(
        boldName: String? = nil,
        italicName: String? = nil,
        boldItalicName: String? = nil,
        fallbackNames: [String] = [],
        variations: [FontVariationAxis] = []
    ) {
        self.boldName = boldName
        self.italicName = italicName
        self.boldItalicName = boldItalicName
        self.fallbackNames = fallbackNames
        self.variations = variations
    }
}
