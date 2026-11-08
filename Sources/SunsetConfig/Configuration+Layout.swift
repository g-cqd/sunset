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

        public var tabSpacing = 4.0
        public var tabSideInset = 2.0
        public var tabPaddingLeading = 8.0
        public var tabPaddingTrailing = 4.0
        public var tabPaddingVertical = 3.0
        public var tabRadius = 6.0
        public var closeButtonSize = 20.0
        public var closeButtonRadius = 4.0
        /// The tab metrics of the floating panel (it can look different from the docked sidebar): spacing 3 (half of what it was), the rest as the docked ones were.
        public var floatingTabSpacing = 3.0
        public var floatingTabSideInset = 4.0
        public var floatingTabPaddingLeading = 8.0
        public var floatingTabPaddingTrailing = 4.0
        public var floatingTabPaddingVertical = 3.0
        public var floatingTabRadius = 6.0
        public var floatingCloseButtonSize = 20.0
        public var floatingCloseButtonRadius = 4.0
        /// Width of the strip that resizes the sidebar by dragging.
        public var resizeHandleWidth = 8.0
        public var lightsInset = 8.0
        public var lightsGap = 10.0
        public var floatingLightsExtra = 0.0
        public var pinButtonSize = 24.0
        public var pinButtonRadius = 5.0
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

        /// The layout with the tab metrics the floating panel draws with (its own `floatingTab*` and `floatingCloseButton*`) in place of the docked ones.
        public var floatingTabs: Layout {
            var copy = self
            copy.tabSpacing = floatingTabSpacing
            copy.tabSideInset = floatingTabSideInset
            copy.tabPaddingLeading = floatingTabPaddingLeading
            copy.tabPaddingTrailing = floatingTabPaddingTrailing
            copy.tabPaddingVertical = floatingTabPaddingVertical
            copy.tabRadius = floatingTabRadius
            copy.closeButtonSize = floatingCloseButtonSize
            copy.closeButtonRadius = floatingCloseButtonRadius
            return copy
        }
    }
}
