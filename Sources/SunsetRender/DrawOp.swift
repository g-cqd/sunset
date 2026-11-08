/// One pixel operation of a frame, in the order the CPU renderer would perform it. A frame is a list of these (`DrawFrame`); the CPU renderer executes them as
/// it goes, a GPU renderer replays the list (ADR-0024: one description, two backends). Pixels are packed like `Surface` pixels (red, green, blue, alpha from the
/// lowest byte), premultiplied by the alpha when the frame is translucent.
///
/// Plain values, 32 bytes, the layout a GPU instance has: recording a frame appends these without reference counting (an enum holding the glyph's bitmap
/// cost 290 instructions an operation to record, renderer plan 2026-11-08).
public struct DrawOp: Sendable, Equatable {
    /// The rectangle the operation writes (already clipped to the surface, and for a glyph to its cell).
    public var x: Int32
    public var y: Int32
    public var width: Int32
    public var height: Int32
    public var color: UInt32
    /// 0: the rectangle is set to `color`. Otherwise `color` is blended over it with the coverage of the frame's glyph number `glyph` (`DrawFrame.glyph(of:)`:
    /// 1 is the first of `DrawFrame.glyphs`), starting at (`sourceX`, `sourceY`) in that bitmap. Coverage 0 leaves a pixel alone.
    public var glyph: UInt32
    public var sourceX: Int32
    public var sourceY: Int32

    /// Sets the rectangle to `color`.
    public static func fill(x: Int, y: Int, width: Int, height: Int, color: UInt32) -> DrawOp {
        DrawOp(
            x: Int32(x),
            y: Int32(y),
            width: Int32(width),
            height: Int32(height),
            color: color,
            glyph: 0,
            sourceX: 0,
            sourceY: 0
        )
    }
}
