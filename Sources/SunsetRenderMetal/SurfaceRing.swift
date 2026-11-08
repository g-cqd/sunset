internal import CoreGraphics
internal import IOSurface
internal import Metal

/// The `IOSurface`s a window's layer shows, drawn into in turn: never the one shown last, nor one the window server still holds (`isInUse`), so that a frame
/// is not written while it is on screen. Two are enough while the window server lets go of a surface before the next frame; when frames come faster (output
/// scrolling), the one shown before is often still held, and a third is made. It is let go again on the first frame after the window was quiet for a while.
/// (Measured in the app, 100 lines a second: the surface shown before was still held in 79 % of the frames; at a line every 0.3 s, never.)
struct SurfaceRing {
    struct Slot {
        let surface: IOSurface
        let texture: any MTLTexture
        /// Pixel rows of the picture this surface does not have (frames drawn into others since it was last drawn into); nil: none.
        var missing: ClosedRange<Int>?
    }

    static let fewest = 2
    static let most = 3
    /// 'RGBA': the bytes of a pixel are red, green, blue, alpha, as the renderer packs them.
    private static let pixelFormat: Int32 = 0x5247_4241

    let width: Int
    let height: Int
    private let device: any MTLDevice
    private(set) var slots: [Slot] = []
    /// The slot drawn into last, which the layer shows.
    private(set) var shown: Int?
    private var lastFrame: ContinuousClock.Instant?

    init?(device: any MTLDevice, width: Int, height: Int) {
        self.device = device
        self.width = width
        self.height = height
        for _ in 0 ..< Self.fewest {
            guard let slot = makeSlot() else { return nil }
            slots.append(slot)
        }
    }

    /// The slot to draw the next frame into; nil when a surface could not be made. `quiet`: how long without frames lets the third surface go.
    mutating func next(now: ContinuousClock.Instant, quiet: Duration) -> Int? {
        if slots.count > Self.fewest, let lastFrame, now - lastFrame > quiet { letGoOfOne() }
        let free = slots.indices.filter { $0 != shown && !slots[$0].surface.isInUse }
        // The free surface that misses the fewest rows: the least to bring up to date.
        if let best = free.min(by: { (slots[$0].missing?.count ?? 0) < (slots[$1].missing?.count ?? 0) }) {
            return best
        }
        if slots.count < Self.most, let slot = makeSlot() {
            slots.append(slot)
            return slots.count - 1
        }
        // Every other surface is still held (not seen in practice with three): the one that is not shown is taken, as a fixed ring would.
        return slots.indices.first { $0 != shown }
    }

    /// The frame was drawn into slot `index`, changing the pixel rows `changed`: it is shown now, and the others miss those rows.
    mutating func drawn(_ index: Int, changed: ClosedRange<Int>, at now: ContinuousClock.Instant) {
        for other in slots.indices where other != index {
            slots[other].missing =
                slots[other].missing
                .map { min($0.lowerBound, changed.lowerBound) ... max($0.upperBound, changed.upperBound) } ?? changed
        }
        slots[index].missing = nil
        shown = index
        lastFrame = now
    }

    /// Drops a surface that is neither shown nor held.
    private mutating func letGoOfOne() {
        guard let index = slots.indices.last(where: { $0 != shown && !slots[$0].surface.isInUse }) else { return }
        slots.remove(at: index)
        if let current = shown, current > index { shown = current - 1 }
    }

    /// A surface and the texture over it; it has none of the picture yet.
    private func makeSlot() -> Slot? {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        descriptor.usage = [.renderTarget, .shaderRead]
        guard
            let surface = IOSurface(properties: [
                .width: width, .height: height, .bytesPerElement: 4, .pixelFormat: Self.pixelFormat
            ]), let texture = device.makeTexture(descriptor: descriptor, iosurface: surface, plane: 0)
        else { return nil }
        if let colorSpace = CGColorSpace(name: CGColorSpace.sRGB), let list = colorSpace.copyPropertyList() {
            surface.setAttachment(list, forKey: kIOSurfaceColorSpace as String)
        }
        return Slot(surface: surface, texture: texture, missing: 0 ... height - 1)
    }
}
