/// What a frame changes in the surface: the operations, in order. The surface is kept between frames (only the rows that changed are in the list, or
/// everything after a full redraw), so a backend applies the list to what it holds.
public struct DrawFrame: Sendable {
    public let width: Int
    public let height: Int
    public let ops: ContiguousArray<DrawOp>
    /// The renderer's glyph table: a glyph operation names its bitmap by its place here (`glyph(of:)`). A place keeps its bitmap from frame to frame while
    /// `glyphGeneration` stays the same, so a backend can remember what it uploaded by place; the table only grows within a generation.
    public let glyphs: ContiguousArray<GlyphBitmap>
    /// Changes when the renderer started its glyph table again: places a backend remembers from an earlier generation mean nothing now. Unique in the process
    /// (no two renderers share one); 0 is never given out, it is for frames made by hand.
    public let glyphGeneration: UInt32
    /// The default background is translucent (`FrameView.backgroundAlpha` below 255): colours are premultiplied and text is blended over a destination of any
    /// alpha.
    public let translucent: Bool
    /// The pixel rows the operations touch (the whole surface after a full redraw); nil when there are none.
    public let changedPixelRows: ClosedRange<Int>?

    public init(
        width: Int,
        height: Int,
        ops: ContiguousArray<DrawOp>,
        glyphs: ContiguousArray<GlyphBitmap> = [],
        glyphGeneration: UInt32 = 0,
        translucent: Bool,
        changedPixelRows: ClosedRange<Int>?
    ) {
        precondition(
            ops.allSatisfy { Int($0.glyph) <= glyphs.count },
            "every glyph operation names a glyph of the table"
        )
        self.width = width
        self.height = height
        self.ops = ops
        self.glyphs = glyphs
        self.glyphGeneration = glyphGeneration
        self.translucent = translucent
        self.changedPixelRows = changedPixelRows
    }

    /// The bitmap a glyph operation blends; nil for a fill.
    public func glyph(of op: DrawOp) -> GlyphBitmap? {
        op.glyph == 0 ? nil : glyphs[Int(op.glyph) - 1]
    }

    /// Applies the operations to `surface` on the CPU with the renderer's own kernels: the reference a GPU backend is compared with, and a check that the list
    /// holds everything the CPU renderer writes.
    public func replay(onto surface: inout Surface) {
        for op in ops {
            let (x, y, width, height) = (Int(op.x), Int(op.y), Int(op.width), Int(op.height))
            guard let bitmap = glyph(of: op) else {
                for row in y ..< y + height {
                    let start = row * surface.width + x
                    for index in start ..< start + width { surface.pixels[index] = op.color }
                }
                continue
            }
            for row in 0 ..< height {
                let line = (y + row) * surface.width + x
                let source = (Int(op.sourceY) + row) * bitmap.width + Int(op.sourceX)
                bitmap.coverage.withUnsafeBufferPointer { coverage in
                    surface.pixels.withUnsafeMutableBufferPointer { pixels in
                        guard let base = pixels.baseAddress, let alphas = coverage.baseAddress else { return }
                        if translucent {
                            PixelKernels.blendPremultipliedScalar(
                                base + line,
                                coverage: alphas + source,
                                count: width,
                                color: op.color
                            )
                        } else {
                            PixelKernels.blendScalar(
                                base + line,
                                coverage: alphas + source,
                                count: width,
                                color: op.color
                            )
                        }
                    }
                }
            }
        }
    }
}
