/// One pixel operation of a frame, in the order the CPU renderer would perform it. A frame is a list of these (`DrawFrame`); the CPU renderer executes them as
/// it goes, a GPU renderer replays the list (ADR-0024: one description, two backends). Pixels are packed like `Surface` pixels (red, green, blue, alpha from the
/// lowest byte), premultiplied by the alpha when the frame is translucent.
public enum DrawOp: Sendable {
    /// Sets a rectangle (already clipped to the surface) to `color`.
    case fill(x: Int, y: Int, width: Int, height: Int, color: UInt32)
    /// Blends `color` over a rectangle of the surface with the glyph's coverage: the part of `bitmap` that starts at (`sourceX`, `sourceY`) and is `width` x
    /// `height`, placed with its top left at (`x`, `y`) (already clipped to the cell and the surface). Coverage 0 leaves a pixel alone.
    case glyph(bitmap: GlyphBitmap, sourceX: Int, sourceY: Int, width: Int, height: Int, x: Int, y: Int, color: UInt32)
}
