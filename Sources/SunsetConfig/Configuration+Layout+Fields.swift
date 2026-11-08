extension Configuration.Layout {
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
            "floatingTabSpacing",
            "Floating: space between tabs",
            ["gap", "margin", "panel", "hover"],
            0 ... 24,
            1,
            \.floatingTabSpacing
        ),
        field(
            "floatingTabSideInset",
            "Floating: tabs' space to the panel's sides",
            ["margin", "edge", "panel", "hover"],
            0 ... 24,
            1,
            \.floatingTabSideInset
        ),
        field(
            "floatingTabPaddingLeading",
            "Floating: tab padding, leading",
            ["inner", "panel", "title"],
            0 ... 32,
            1,
            \.floatingTabPaddingLeading
        ),
        field(
            "floatingTabPaddingTrailing",
            "Floating: tab padding, trailing",
            ["inner", "panel"],
            0 ... 32,
            1,
            \.floatingTabPaddingTrailing
        ),
        field(
            "floatingTabPaddingVertical",
            "Floating: tab padding, vertical",
            ["inner", "panel", "height"],
            0 ... 24,
            1,
            \.floatingTabPaddingVertical
        ),
        field(
            "floatingTabRadius",
            "Floating: tab corner radius",
            ["rounding", "panel", "corners"],
            0 ... 24,
            1,
            \.floatingTabRadius
        ),
        field(
            "floatingCloseButtonSize",
            "Floating: close button size",
            ["tab", "panel", "x"],
            8 ... 32,
            1,
            \.floatingCloseButtonSize
        ),
        field(
            "floatingCloseButtonRadius",
            "Floating: close button corner radius",
            ["tab", "panel", "x"],
            0 ... 16,
            1,
            \.floatingCloseButtonRadius
        ),
        field(
            "resizeHandleWidth",
            "Resize handle width",
            ["drag", "grab", "hit box", "sidebar", "border"],
            2 ... 24,
            1,
            \.resizeHandleWidth
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
            "paneGap",
            "Gap between split panes",
            ["split", "divider", "pane", "space"],
            0 ... 16,
            1,
            \.paneGap
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

    static func field(
        _ key: String,
        _ title: String,
        _ keywords: [String],
        _ range: ClosedRange<Double>,
        _ step: Double,
        _ path: WritableKeyPath<Configuration.Layout, Double>,
        unit: String = "pt"
    ) -> Field {
        Field(key: key, title: title, keywords: keywords, range: range, step: step, unit: unit, path: path)
    }
}
