/// What a frame changes in the surface: the operations, in order. The surface is kept between frames (only the rows that changed are in the list, or
/// everything after a full redraw), so a backend applies the list to what it holds.
public struct DrawFrame: Sendable {
    public let width: Int
    public let height: Int
    public let ops: [DrawOp]
    /// The default background is translucent (`FrameView.backgroundAlpha` below 255): colours are premultiplied and text is blended over a destination of any
    /// alpha.
    public let translucent: Bool
    /// The pixel rows the operations touch (the whole surface after a full redraw); nil when there are none.
    public let changedPixelRows: ClosedRange<Int>?

    public init(width: Int, height: Int, ops: [DrawOp], translucent: Bool, changedPixelRows: ClosedRange<Int>?) {
        self.width = width
        self.height = height
        self.ops = ops
        self.translucent = translucent
        self.changedPixelRows = changedPixelRows
    }

    /// Applies the operations to `surface` on the CPU with the renderer's own kernels: the reference a GPU backend is compared with, and a check that the list
    /// holds everything the CPU renderer writes.
    public func replay(onto surface: inout Surface) {
        for op in ops {
            switch op {
                case .fill(let x, let y, let width, let height, let color):
                    for row in y ..< y + height {
                        let start = row * surface.width + x
                        for index in start ..< start + width { surface.pixels[index] = color }
                    }
                case .glyph(let bitmap, let sourceX, let sourceY, let width, let height, let x, let y, let color):
                    for row in 0 ..< height {
                        let line = (y + row) * surface.width + x
                        let source = (sourceY + row) * bitmap.width + sourceX
                        bitmap.coverage.withUnsafeBufferPointer { coverage in
                            surface.pixels.withUnsafeMutableBufferPointer { pixels in
                                guard let base = pixels.baseAddress, let alphas = coverage.baseAddress else { return }
                                if translucent {
                                    PixelKernels.blendPremultipliedScalar(
                                        base + line,
                                        coverage: alphas + source,
                                        count: width,
                                        color: color
                                    )
                                } else {
                                    PixelKernels.blendScalar(
                                        base + line,
                                        coverage: alphas + source,
                                        count: width,
                                        color: color
                                    )
                                }
                            }
                        }
                    }
            }
        }
    }
}
