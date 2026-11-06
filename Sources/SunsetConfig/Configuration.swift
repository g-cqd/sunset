/// Everything the configuration file sets, with the defaults used for any key it does not mention.
public struct Configuration: Sendable, Equatable {
    public struct Font: Sendable, Equatable {
        /// nil: the app's default monospaced font.
        public var family: String?
        public var size = 14.0
        public var ligatures = true
        public init() {}
    }

    public struct Colors: Sendable, Equatable {
        /// `#rrggbb` as red, green, blue; nil keeps the terminal's own palette.
        public var foreground: [UInt8]?
        public var background: [UInt8]?
        public var cursor: [UInt8]?
        public init() {}
    }

    public enum Renderer: String, Sendable, Equatable, CaseIterable {
        case auto, gpu, cpu
    }

    public var font = Font()
    public var colors = Colors()
    /// Lines of history kept per terminal.
    public var scrollbackLines = 10_000
    /// Seconds without input or output after which the cursor stops blinking; nil: it blinks for ever.
    public var cursorBlinkTimeout: Double? = 15
    public var renderer = Renderer.auto

    public init() {}
}
