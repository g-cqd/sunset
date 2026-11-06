internal import SunsetCore

/// A shaped run in the cache: the scalars it was made from (to tell hash collisions apart), the style flags and the bitmap (nil: it draws nothing).
final class RunEntry {
    let scalars: [UInt32]
    let bold: Bool
    let italic: Bool
    let bitmap: GlyphBitmap?

    init(scalars: [UInt32], bold: Bool, italic: Bool, bitmap: GlyphBitmap?) {
        self.scalars = scalars
        self.bold = bold
        self.italic = italic
        self.bitmap = bitmap
    }
}
