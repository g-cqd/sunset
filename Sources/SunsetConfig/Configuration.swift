/// Everything the configuration file sets, with the defaults used for any key it does not mention.
public struct Configuration: Sendable, Equatable {
    public struct Font: Sendable, Equatable {
        /// nil: the app's default monospaced font.
        public var family: String?
        public var size = 14.0
        public var ligatures = true
        /// OpenType features as `tag` or `tag=value`, separated by commas: `zero, ss01, cv02=3`.
        public var features = ""
        public init() {}
    }

    public struct Colors: Sendable, Equatable {
        /// `#rrggbb` as red, green, blue; nil keeps the terminal's own palette.
        public var foreground: [UInt8]?
        public var background: [UInt8]?
        public var cursor: [UInt8]?
        public init() {}
    }

    public struct Window: Sendable, Equatable {
        public enum Decorations: String, Sendable, Equatable, CaseIterable {
            /// No title bar: the content fills the window, the traffic lights stay (where `trafficLights` puts them) and a strip at the top drags the window.
            case none
            /// The system's title bar.
            case native
        }

        public var decorations = Decorations.none
        /// Where the traffic lights are, in points from the window top left corner to the top left of the close button (with no decorations); the default centres them in the 16 pt strip.
        public var trafficLightsX = 12.0
        public var trafficLightsY = 1.0
        /// The height in points of the strip at the top of the window that drags it (with no decorations); 0 for none.
        public var dragStrip = 16.0
        /// Space between the window's edge and the terminal, in points (0: the text reaches the edge).
        public var padding = 0.0
        public var material = Material.opaque
        /// How opaque the terminal's default background is with `transparent` (0 to 1).
        public var opacity = 0.8
        /// The radius of the blur behind a `transparent` window, in points (0 to 100).
        public var blur = 0.0
        public init() {}
    }

    /// What is behind the terminal (and the sidebar).
    public enum Material: String, Sendable, Equatable, CaseIterable {
        /// A solid colour.
        case opaque
        /// A system material (`NSVisualEffectView`) that blurs what is behind the window.
        case material
        /// Liquid Glass (`NSGlassEffectView`, macOS 26).
        case glass
        /// Nothing: the desktop shows through the default background, blurred by `blur`.
        case transparent
    }

    public struct Sidebar: Sendable, Equatable {
        public var enabled = false
        /// Width in points.
        public var width = 200.0
        /// Space between the terminal and the window's edge and the sidebar while the sidebar is shown, in points (2 to 4).
        public var padding = 3.0
        public var material = Material.material
        public var blur = 0.0
        public init() {}
    }

    /// Looks shared by the window and the sidebar.
    public struct Appearance: Sendable, Equatable {
        public enum Glass: String, Sendable, Equatable, CaseIterable {
            case regular, clear
        }

        public var glass = Glass.regular
        /// `#rrggbb`; nil for no tint. One tint for the window and the sidebar.
        public var tintColor: [UInt8]?
        public var tintAlpha = 0.25
        public init() {}
    }

    public struct Tabs: Sendable, Equatable {
        public enum Mode: String, Sendable, Equatable, CaseIterable {
            /// One terminal per window.
            case none
            /// The system's tabs (and the sidebar, when on, lists the same tabs).
            case native
            /// A tab bar in the terminal window itself; native tabs and the sidebar are off.
            case `internal`
        }

        public struct Bar: Sendable, Equatable {
            public enum Position: String, Sendable, Equatable, CaseIterable {
                case top, bottom
            }

            public var position = Position.top
            public var showTitle = true
            public var showDirectory = false
            public var showProgress = true
            public init() {}
        }

        public var mode = Mode.native
        public var bar = Bar()
        public init() {}
    }

    public struct Scroll: Sendable, Equatable {
        /// Lines scrolled per cell height of finger travel on a trackpad (1: the text follows the finger).
        public var trackpad = 1.0
        /// Lines scrolled per notch of a wheel (the system reports one line per notch, more when it accelerates).
        public var wheel = 3.0
        public init() {}
    }

    public struct Keyboard: Sendable, Equatable {
        /// Option sends Escape before the key (Meta) instead of composing a character.
        public var optionAsMeta = false
        public init() {}
    }

    public enum Renderer: String, Sendable, Equatable, CaseIterable {
        case auto, gpu, cpu
    }

    public var font = Font()
    public var colors = Colors()
    public var window = Window()
    public var scroll = Scroll()
    public var keyboard = Keyboard()
    public var sidebar = Sidebar()
    public var appearance = Appearance()
    public var tabs = Tabs()
    /// The name of a theme file (`themes/<name>.json` beside the configuration file), or nil.
    public var theme: String?
    /// Lines of history kept per terminal.
    public var scrollbackLines = 10_000
    /// Seconds without input or output after which the cursor stops blinking; nil: it blinks for ever.
    public var cursorBlinkTimeout: Double? = 15
    public var renderer = Renderer.auto

    public init() {}
}

extension Configuration {
    /// The cursor's blink timeout as a number for a control: 15 while it blinks for ever (the value a control shows when it is switched back on).
    public var cursorBlinkTimeoutSeconds: Double {
        get { cursorBlinkTimeout ?? 15 }
        set { cursorBlinkTimeout = newValue }
    }
}
