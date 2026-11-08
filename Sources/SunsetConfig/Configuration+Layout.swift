extension Configuration {
    /// The measures of the sidebar, the tabs, the traffic lights and the terminal card, all in points unless said otherwise. They are tuned by eye, so each is
    /// a setting (`layout.*`); the defaults are the values the interface had when they were fixed.
    public struct Layout: Sendable, Equatable {
        /// One numeric metric (a key path to a plain `Double`, which is why `@unchecked Sendable` is sound): its key, a title for Settings, the range it accepts and the step of its stepper.
        public struct Field: @unchecked Sendable {
            public let key: String
            public let title: String
            public let keywords: [String]
            public let range: ClosedRange<Double>
            public let step: Double
            public let unit: String
            public let path: WritableKeyPath<Layout, Double>
        }

        public var tabSpacing = 6.0
        public var tabSideInset = 4.0
        public var tabPaddingLeading = 8.0
        public var tabPaddingTrailing = 4.0
        public var tabPaddingVertical = 3.0
        public var tabRadius = 6.0
        public var closeButtonSize = 20.0
        public var closeButtonRadius = 4.0
        public var lightsInset = 6.0
        public var lightsGap = 10.0
        public var floatingLightsExtra = 2.0
        public var pinButtonSize = 24.0
        public var pinButtonRadius = 6.0
        public var hairlineWidth = 0.5
        public var hairlineOpacity = 0.12
        public var revealStripWidth = 10.0
        /// Seconds the floating sidebar stays after the pointer leaves it.
        public var hideDelay = 0.35
        /// Seconds of the one transition between states (hover, selection, pinning).
        public var animation = 0.15
        /// Corner radius of the terminal card while the sidebar is docked; nil: concentric with the window's corners (the window's radius minus the margin).
        public var terminalRadius: Double?
        /// Corner radius of the floating panel; nil: concentric with the window's corners.
        public var panelRadius: Double?

        public init() {}

        /// Every numeric metric, in the order of the file and of Settings.
        public static let fields: [Field] = [
            field("tabSpacing", "Space between tabs", ["gap", "margin", "list"], 0 ... 24, 1, \.tabSpacing),
            field(
                "tabSideInset",
                "Tabs: space to the sidebar's sides",
                ["margin", "edge", "leading", "trailing"],
                0 ... 24,
                1,
                \.tabSideInset
            ),
            field(
                "tabPaddingLeading",
                "Tab padding, leading",
                ["inner", "left", "title"],
                0 ... 32,
                1,
                \.tabPaddingLeading
            ),
            field("tabPaddingTrailing", "Tab padding, trailing", ["inner", "right"], 0 ... 32, 1, \.tabPaddingTrailing),
            field(
                "tabPaddingVertical",
                "Tab padding, vertical",
                ["inner", "height", "top", "bottom"],
                0 ... 24,
                1,
                \.tabPaddingVertical
            ),
            field("tabRadius", "Tab corner radius", ["rounding", "round", "corners"], 0 ... 24, 1, \.tabRadius),
            field("closeButtonSize", "Close button size", ["tab", "hit box", "x"], 8 ... 32, 1, \.closeButtonSize),
            field(
                "closeButtonRadius",
                "Close button corner radius",
                ["rounding", "tab", "x"],
                0 ... 16,
                1,
                \.closeButtonRadius
            ),
            field(
                "lightsInset",
                "Traffic lights: inset",
                ["top", "leading", "corner", "buttons", "distance"],
                0 ... 32,
                1,
                \.lightsInset
            ),
            field(
                "lightsGap",
                "Traffic lights: space to the first tab",
                ["gap", "below", "buttons"],
                0 ... 32,
                1,
                \.lightsGap
            ),
            field(
                "floatingLightsExtra",
                "Traffic lights: extra inset when floating",
                ["panel", "hover", "buttons"],
                0 ... 16,
                1,
                \.floatingLightsExtra
            ),
            field(
                "pinButtonSize",
                "Pin button size",
                ["container", "hit box", "sidebar button"],
                12 ... 40,
                1,
                \.pinButtonSize
            ),
            field(
                "pinButtonRadius",
                "Pin button corner radius",
                ["rounding", "container"],
                0 ... 20,
                1,
                \.pinButtonRadius
            ),
            field(
                "hairlineWidth",
                "Hairline width",
                ["stroke", "border", "thin", "line"],
                0 ... 2,
                0.25,
                \.hairlineWidth
            ),
            field(
                "hairlineOpacity",
                "Hairline opacity",
                ["stroke", "border", "thin", "line"],
                0 ... 1,
                0.02,
                \.hairlineOpacity,
                unit: ""
            ),
            field(
                "revealStripWidth",
                "Hover strip width",
                ["reveal", "edge", "floating", "sidebar"],
                2 ... 40,
                1,
                \.revealStripWidth
            ),
            field(
                "hideDelay",
                "Floating sidebar: hide delay",
                ["leave", "floating", "hover"],
                0 ... 3,
                0.05,
                \.hideDelay,
                unit: "s"
            ),
            field(
                "animation",
                "Transition duration",
                ["animation", "smooth", "hover", "speed"],
                0 ... 1,
                0.01,
                \.animation,
                unit: "s"
            )
        ]

        private static func field(
            _ key: String,
            _ title: String,
            _ keywords: [String],
            _ range: ClosedRange<Double>,
            _ step: Double,
            _ path: WritableKeyPath<Layout, Double>,
            unit: String = "pt"
        ) -> Field {
            Field(key: key, title: title, keywords: keywords, range: range, step: step, unit: unit, path: path)
        }
    }
}
