internal import Metal
internal import SunsetRender

/// The glyphs' coverage on the GPU: one 8-bit texture the glyph bitmaps are packed into, row by row (shelves). A bitmap is uploaded the first time a frame
/// needs it and found again by identity (the CPU renderer keeps a glyph's bitmap for as long as it caches it). When the texture is full the atlas starts again
/// and the frame's glyphs are uploaded afresh.
struct GlyphAtlas {
    struct Slot {
        let x: Int
        let y: Int
        /// Keeps the bitmap alive, so that its identity is not reused for another while it is a key.
        let bitmap: GlyphBitmap
    }

    static let size = 2048

    let texture: any MTLTexture
    private var slots: [ObjectIdentifier: Slot] = [:]
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

    /// Where `bitmap` is in the atlas; uploads it if it is new. nil when it does not fit (the atlas is full).
    mutating func slot(for bitmap: GlyphBitmap) -> Slot? {
        let key = ObjectIdentifier(bitmap)
        if let known = slots[key] { return known }
        guard bitmap.width <= Self.size, bitmap.height <= Self.size else { return nil }
        if cursorX + bitmap.width > Self.size {
            shelfY += shelfHeight
            cursorX = 0
            shelfHeight = 0
        }
        guard shelfY + bitmap.height <= Self.size else { return nil }
        let slot = Slot(x: cursorX, y: shelfY, bitmap: bitmap)
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
        slots[key] = slot
        return slot
    }

    /// Forgets every glyph (the texture's contents are overwritten as new ones arrive).
    mutating func clear() {
        slots.removeAll(keepingCapacity: true)
        shelfY = 0
        shelfHeight = 0
        cursorX = 0
    }

    var count: Int { slots.count }
}
