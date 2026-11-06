// The platform seam of the renderer on macOS (white paper section 9): glyphs rasterised by CoreText into coverage bitmaps. Nothing else imports CoreText.

internal import CoreGraphics
internal import CoreText
internal import SunsetRender

/// An OpenType feature to turn on, off or select a variant of: `liga`, `calt` (ligatures and contextual alternates), `zero` (slashed zero), `ss01`...`ss20`
/// (stylistic sets), `cv01`..., `ccmp`, ... A value of 0 turns the feature off, 1 on, more picks an alternate where the font has several.
public struct FontFeature: Sendable, Equatable {
    public var tag: String
    public var value: Int

    public init(_ tag: String, _ value: Int = 1) {
        self.tag = tag
        self.value = value
    }
}
