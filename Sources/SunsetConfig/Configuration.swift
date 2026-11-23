public import SunsetMetrics

/// Everything the configuration file sets, with the defaults used for any key it does not mention.
public struct Configuration: Sendable, Equatable {
    public struct Font: Sendable, Equatable {
        /// nil: the app's default monospaced font.
        public var family: String? = "JetBrains Mono"
        public var size = 12.0
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
        public var material = Material.glass
        /// How thick the `material` background is.
        public var materialThickness = MaterialThickness.regular
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
        /// A colour with alpha: the tint (`appearance.tint`), the desktop showing through it, nothing blurred. Read also as
        /// `transparent`, its name before.
        case fill
    }

    /// An edge of the window.
    public enum Side: String, Sendable, Equatable, CaseIterable {
        case left, right
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
        public var tintColor: [UInt8]? = [0x00, 0x00, 0x00]
        /// The tint while the scheme is light, and its strength (black text on the dark tint did not read).
        public var lightTintColor: [UInt8]? = [0xFF, 0xFF, 0xFF]
        public var lightTintAlpha = 0.8
        public var tintAlpha = 0.5
        /// The colour that marks a selection, a focus, a filled control (design 0003 §3.5): the system's accent, Sunset's (`tint.color`, the
        /// system's when unset), neutral shades of the scheme, or the shown site's colour.
        public var accent = Accent.system
        /// The trackpad taps when a click goes through or is blocked.
        public var haptics = true
        /// What is under the bars (the address bar, the find bar, the ends of the sidebar's list) and behind the command bar: a
        /// blur that fades out (AemiSDR's variable blur), the surface the bar draws itself, or nothing.
        public var barBlur = BarBlur.variable
        public var ends = Ends.fade
        /// The app's icon in the Dock and the app switcher while Sunset runs.
        public var icon = Icon.auto
        /// The bars' fill and controls (`BarTint`); `scheme` follows the colour scheme.
        public var barTint = BarTint.scheme
        public init() {}
    }

    public struct Tabs: Sendable, Equatable {
        public struct Bar: Sendable, Equatable {
            public enum Position: String, Sendable, Equatable, CaseIterable {
                case top, bottom
            }

            public var position = Position.bottom
            public var autoHide = true  // Hidden over the page until the pointer reaches its edge.
            public var backing = Backing.fade  // Under it while shown always: the page fading, or a toolbar (0055 C).
            public var showTitle = true
            /// A small picture before the title: a folder with the first letter of the directory's name, or a mark for a running command.
            public var showIcon = true
            public var showDirectory = true
            /// The second line (the directory, a page's address) in the monospaced face.
            public var monospacedDirectory = true
            public var showProgress = true
            public init() {}
        }

        public var mode = Mode.native
        /// What Command-T makes.
        public var newTab = NewTab.focused
        /// What opens with no tab: nothing, a kind of tab, `startAddress`, `startFile`; `startProfile` names the
        /// profile whose first Space a new window opens on (empty: as before).
        public var start = Start.nothing
        public var startAddress = ""
        public var startFile = ""
        public var startProfile = ""
        /// A tab coloured by its site.
        public var siteColor = SiteColor.off
        public var bar = Bar()
        /// The tabs of each window (their splits and the directory of each) come back at the next launch, as new shells there (programs cannot be saved).
        public var restore = true
        /// Closing a tab with a running command tints it red on the first click or ⌘W and requires a second one to confirm.
        public var confirmClose = true
        /// Closing the last window does not quit the app while a kept entry of the Favorites is open: what runs in it goes on, and a new window shows it
        /// again. Off: the app quits with its last window, as before.
        public var keepRunningForFavorites = true
        /// Quitting asks first: never, when something would be lost (a running command, a form being filled, a download, tabs
        /// that will not come back), or always.
        public var askBeforeQuit = QuitAsk.whenLosing
        /// The tabs of a Space when its last window closes: they stop and stay, for the next window or the next launch.
        /// On: they close with it, as before Spaces.
        public var closeWithLastWindow = false
        /// Tabs that stayed, stopped, are closed once this many hours have passed with no window showing them; 0 is never.
        public var closeStoppedAfter = 0.0
        /// The window when the last tab of its Space closes: it stays, on the empty Space. On: it closes with the tab,
        /// as before Spaces.
        public var closeWindowWithLastTab = false
        /// Closing the shown tab shows the tab shown before it; off, its neighbour.
        public var closeGoesBack = true
        /// A tab or a window kept awake keeps the display on too, not only the Mac from sleeping.
        public var keepAwakeDisplay = false
        public init() {}

        public enum QuitAsk: String, Sendable, Equatable, CaseIterable {
            case never, whenLosing, always
        }
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
    public var storage = Storage()
    public var documents = Documents()
    public var spaces = Spaces()
    public var features = Features()
    public var web = Web()
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
    public var cursorShape = CursorShape.bar
    public var cursorBlinks = true
    public var renderer = Renderer.auto
    public var updates = Updates()
    public var passwords = Passwords()

    public init() {}
}

extension Configuration {
    /// The cursor's blink timeout as a number for a control: 15 while it blinks for ever (the value a control shows when it is switched back on).
    public var cursorBlinkTimeoutSeconds: Double {
        get {
            cursorBlinkTimeout ?? 15
        }
        set {
            cursorBlinkTimeout = newValue
        }
    }
}
