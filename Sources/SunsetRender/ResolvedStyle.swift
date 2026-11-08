internal import SunsetCore

/// A cell style as one frame draws it: its colours worked out (palette, reverse video, inverse, faint) and the flags the walk tests on every cell. Made once a
/// frame for each style the frame draws (`ResolvedStyles`), not once a cell: resolving was a quarter of a recorded frame (renderer plan 2026-11-08).
struct ResolvedStyle {
    var foreground: RGB
    var background: RGB
    /// The style's own colour for underlines; nil: the foreground the cell is drawn with (after selection or the cursor swapped it).
    var line: RGB?
    var bold: Bool
    var italic: Bool
    var blinks: Bool
    /// Invisible, or blinking in the hidden phase: the glyph is not drawn.
    var hidden: Bool
    /// It has an underline, a strikethrough or an overline.
    var decorated: Bool

    init(_ style: CellStyle, frame: CPURenderer.Frame) {
        let attributes = style.attributes
        (foreground, background) = CPURenderer.colors(of: style, frame: frame)
        line = frame.palette.resolve(style.underlineColor)
        bold = attributes.contains(.bold)
        italic = attributes.contains(.italic)
        blinks = attributes.contains(.blink)
        hidden = attributes.contains(.invisible) || (blinks && !frame.blinkVisible)
        decorated = style.underline != .none || attributes.contains(.strikethrough) || attributes.contains(.overline)
    }
}
