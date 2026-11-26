/// Terminal font configuration (T-7 / t182): primary family, optional per-style overrides (`bold`, `italic`,
/// `boldItalic`), ordered `fallbacks`, point `size`, `ligatures`, OpenType `features`, and variable-font `variations`.
extension Configuration {
    public struct Font: Sendable, Equatable {
        /// nil: the app's default monospaced font.
        public var family: String? = "JetBrains Mono"
        /// Fonts for bold, italic, and bold-italic text: a family (its face in that style) or a face; nil, or one not
        /// installed, takes `family`'s own face in that style.
        public var boldFamily: String?
        public var italicFamily: String?
        public var boldItalicFamily: String?
        /// Comma-separated ordered fallback font families consulted before the system cascade.
        public var fallbacks = ""
        public var size = 12.0
        public var ligatures = true
        /// OpenType features as `tag` or `tag=value`, separated by commas: `zero, ss01, cv02=3`.
        public var features = ""
        /// Variable-font axis coordinates for regular text as `tag=value`, separated by commas: `wght=500, opsz=12`.
        public var variations = ""
        public init() {}
    }
}
