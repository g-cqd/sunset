internal import Metal
internal import SunsetRender

/// The glyphs' coverage on the GPU: one 8-bit texture the glyph bitmaps are packed into, row by row (shelves). It only places and uploads; which glyph is where
/// is the compositor's to remember (by the frame's glyph numbers). When the texture is full the atlas starts again and the frame's glyphs are uploaded afresh.
struct GlyphAtlas {
    static let size = 2048

    let texture: any MTLTexture
    /// How many glyphs were placed since the atlas was last cleared.
    private(set) var count = 0
    private var shelfY = 0
    private var shelfHeight = 0
    private var cursorX = 0

    init?(device: any MTLDevice) {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .r8Unorm,
            width: Self.size,
            height: Self.size,
            mipmapped: false
        )
        descriptor.storageMode = .shared
        descriptor.usage = .shaderRead
        guard let texture = device.makeTexture(descriptor: descriptor) else { return nil }
        self.texture = texture
    }

    /// Uploads `bitmap` to a free place and returns it; nil when it does not fit (the atlas is full).
    mutating func place(_ bitmap: GlyphBitmap) -> (x: Int32, y: Int32)? {
        guard bitmap.width <= Self.size, bitmap.height <= Self.size else { return nil }
        if cursorX + bitmap.width > Self.size {
            shelfY += shelfHeight
            cursorX = 0
            shelfHeight = 0
        }
        guard shelfY + bitmap.height <= Self.size else { return nil }
        let slot = (x: cursorX, y: shelfY)
        bitmap.coverage.withUnsafeBytes { bytes in
            guard let base = bytes.baseAddress, bitmap.width > 0, bitmap.height > 0 else { return }
            unsafe texture.replace(
                region: MTLRegionMake2D(slot.x, slot.y, bitmap.width, bitmap.height),
                mipmapLevel: 0,
                withBytes: base,
                bytesPerRow: bitmap.width
            )
        }
        cursorX += bitmap.width
        shelfHeight = max(shelfHeight, bitmap.height)
        count += 1
        return (Int32(slot.x), Int32(slot.y))
    }

    /// Forgets every glyph (the texture's contents are overwritten as new ones arrive).
    mutating func clear() {
        count = 0
        shelfY = 0
        shelfHeight = 0
        cursorX = 0
    }
}
