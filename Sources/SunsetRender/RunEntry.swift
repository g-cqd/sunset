internal import SunsetCore

/// A shaped run in the cache: the scalars it was made from (to tell hash collisions apart), the style flags and its glyph number (`CPURenderer.glyphTable`;
/// 0: it draws nothing).
final class RunEntry {
    let scalars: [UInt32]
    let bold: Bool
    let italic: Bool
    let glyph: UInt32

    init(scalars: [UInt32], bold: Bool, italic: Bool, glyph: UInt32) {
        self.scalars = scalars
        self.bold = bold
        self.italic = italic
        self.glyph = glyph
    }
}
