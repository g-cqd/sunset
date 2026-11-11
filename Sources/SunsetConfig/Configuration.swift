/// Everything the configuration file sets, with the defaults used for any key it does not mention.
public struct Configuration: Sendable, Equatable {
    public struct Font: Sendable, Equatable {
        /// nil: the app's default monospaced font.
        public var family: String? = "Maple Mono NF CN"
        public var size = 14.0
        public var ligatures = true
        /// OpenType features as `tag` or `tag=value`, separated by commas: `zero, ss01, cv02=3`.
        public var features = ""
        public init() {}
    }

    public struct Colors: Sendable, Equatable {
        /// `#rrggbb` as red, green, blue. The defaults are the author's (white on black, Kitty's 16 ANSI colours); nil (the cursor, or a colour set to null) keeps the terminal's own.
        public var foreground: [UInt8]? = [0xFF, 0xFF, 0xFF]
        public var background: [UInt8]? = [0x00, 0x00, 0x00]
        public var cursor: [UInt8]?
        /// The 16 ANSI colours, black to white then their bright variants (Kitty's `color0` to `color15`).
        public var ansi: [[UInt8]] = Colors.kittyAnsi
        public init() {}

        static let kittyAnsi: [[UInt8]] = [
            [0x1D, 0x1F, 0x21], [0xCC, 0x66, 0x66], [0xB5, 0xBD, 0x68], [0xF0, 0xC6, 0x74],
            [0x81, 0xA2, 0xBE], [0xB2, 0x94, 0xB7], [0x8A, 0xBE, 0xB7], [0xC5, 0xC8, 0xC6],
            [0x66, 0x66, 0x66], [0xD5, 0x4E, 0x53], [0xB9, 0xCA, 0x4A], [0xE7, 0xC5, 0x57],
            [0x7A, 0xA6, 0xDA], [0xC3, 0x97, 0xD8], [0x70, 0xC0, 0xB1], [0xEA, 0xEA, 0xEA]
        ]
    }

    public struct Window: Sendable, Equatable {
        public enum Decorations: String, Sendable, Equatable, CaseIterable {
            /// No title bar: the content fills the window, the traffic lights stay (where `trafficLights` puts them) and a strip at the top drags the window.
            case none
            /// The system's title bar.
            case native
        }

        public var decorations = Decorations.none

        public enum LightsSide: String, Sendable, Equatable, CaseIterable {
            case sidebar, left, right

            /// The edge they are on, given the sidebar's.
            public func resolved(sidebar: Side) -> Side {
                switch self {
                    case .sidebar: sidebar
                    case .left: .left
                    case .right: .right
                }
            }
        }
        /// Where the traffic lights are, in points from the window top left corner to the top left of the close button (with no decorations); the default centres them in the 16 pt strip.
        public var trafficLightsX = 8.0
        /// The edge of the window the traffic lights are on: the sidebar's (with the sidebar shown), or one of the two. On the right they are mirrored: the close
        /// button is nearest the edge.
        public var lightsSide = LightsSide.sidebar
        public var trafficLightsY = 8.0
        /// The height in points of the strip at the top of the window that drags it (with no decorations); 0 for none.
        public var dragStrip = 16.0
        /// Space between the window's edge and the terminal, in points (0: the text reaches the edge).
        public var padding = 4.0
        public var material = Material.material
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

    /// An edge of the window.
    public enum Side: String, Sendable, Equatable, CaseIterable {
        case left, right
    }

    public struct Sidebar: Sendable, Equatable {
        public var enabled = true
        /// Width in points.
        public var width = 207.0
        /// Space of the window's colour between the terminal and the window's edge and the sidebar while the sidebar is shown, in points. The terminal is
        /// a card then, its corners concentric with the window's (16 pt): with 6 its radius is 10.
        public var padding = 4.0
        /// The sidebar is hidden, and floats over the terminal as a glass panel (holding the traffic lights) while the pointer is at the leading edge; false: it
        /// stays beside the terminal.
        public var autoHide = false
        /// The edge of the window the sidebar is on.
        public var side = Side.left
        public init() {}
    }

    /// Looks shared by the window and the sidebar.
    public struct Appearance: Sendable, Equatable {
        public enum Glass: String, Sendable, Equatable, CaseIterable {
            case regular, clear
        }

        /// The colour scheme of the terminal windows (the sidebar, the glass, the controls): locked to dark by default; `system` follows macOS.
        public enum Scheme: String, Sendable, Equatable, CaseIterable {
            case dark, light, system
        }

        public var scheme = Scheme.dark
        public var glass = Glass.regular
        /// `#rrggbb`; nil for no tint. One tint for the window and the sidebar.
        public var tintColor: [UInt8]?
        public var tintAlpha = 0.0
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

            public var position = Position.bottom
            public var showTitle = true
            /// A small picture before the title: a folder with the first letter of the directory's name, or a mark for a running command.
            public var showIcon = true
            public var showDirectory = true
            public var showProgress = true
            public init() {}
        }

        public var mode = Mode.native
        public var bar = Bar()
        /// The tabs of each window (their splits and the directory of each) come back at the next launch, as new shells there (programs cannot be saved).
        public var restore = true
        /// Closing a tab with a running command tints it red on the first click or ⌘W and requires a second one to confirm (`n28`).
        public var confirmClose = true
        public init() {}
    }

    public struct Scroll: Sendable, Equatable {
        /// Lines scrolled per cell height of finger travel on a trackpad (1: the text follows the finger).
        public var trackpad = 3.0
        /// Lines scrolled per notch of a wheel (the system reports one line per notch, more when it accelerates).
        public var wheel = 3.0
        /// Seconds for a wheel's speed to fall to 1/e of itself (the text glides after a notch); 0: no inertia. A trackpad has the system's own.
        public var inertia = 0.3
        public init() {}
    }

    /// What only the terminal screen has of its own (the window's settings, material and blur, also give the sidebar its look).
    public struct Terminal: Sendable, Equatable {
        /// How opaque the terminal's default background is when the window is not opaque: 1 shows only the terminal's colour, less lets the window's
        /// material show through.
        public var opacity = 0.0
        /// A program may put text on the clipboard (OSC 52); it can never read it (ADR-0010).
        public var clipboardWrite = true
        /// The shell is taught to mark its prompts (OSC 133), which Previous Prompt and Next Prompt go by. zsh only; the user's files are not changed.
        public var shellIntegration = true
        public init() {}
    }

    public struct Keyboard: Sendable, Equatable {
        /// Option sends Escape before the key (Meta) instead of composing a character.
        public var optionAsMeta = false
        public init() {}
    }

    public enum CursorShape: String, Sendable, Equatable, CaseIterable {
        case block, underline, bar
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
    public var layout = Layout()
    public var terminal = Terminal()
    public var tabs = Tabs()
    /// The name of a theme file (`themes/<name>.json` beside the configuration file), or nil.
    public var theme: String?
    /// Lines of history kept per terminal.
    public var scrollbackLines = 100_000
    /// Seconds without input or output after which the cursor stops blinking; nil: it blinks for ever.
    public var cursorBlinkTimeout: Double? = 15
    /// The shape of the cursor, and whether it blinks, until a program chooses its own (DECSCUSR) and again after it asks for the default.
    public var cursorShape = CursorShape.block
    public var cursorBlinks = true
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
