internal import SunsetCore

/// Every glyph the renderer made, numbered (1 + its place in `bitmaps`; 0 is "no glyph"), and the lookups from a cell to its number. A recorded frame carries
/// `bitmaps` and names glyphs by number (`DrawFrame.glyphs`), so a backend can remember its uploads by number while `generation` stays the same.
///
/// A value, handed down the frame's walk `inout` (`CPURenderer.render`): its lookups run on every cell, and a class's stored property pays a dynamic
/// exclusivity check on each access, which an `inout` value does not (measured: those checks were a tenth of a recorded frame, renderer plan 2026-11-08).
struct GlyphTable {
    struct Key: Hashable {
        var id: UInt32
        var cluster: Bool
        var bold: Bool
        var italic: Bool
        var wide: Bool
    }

    /// Scalars below this have their numbers in `direct`: Latin, Greek, Cyrillic, the symbols, lines, blocks and braille.
    static let directLimit: UInt32 = 0x3000
    /// `direct` before a scalar was looked up.
    static let unknown = UInt32.max

    private(set) var bitmaps: [GlyphBitmap] = []
    private(set) var generation: UInt32
    /// The numbers of single scalars under `directLimit`, by variant (`variant(bold:italic:wide:)`) then scalar: an array read in place of a hashed lookup on
    /// every cell (it was a quarter of a frame's walk). A variant's array is made on its first use (12 288 entries of 4 bytes).
    private var direct: [ContiguousArray<UInt32>] = []
    private var hashed: [Key: UInt32] = [:]

    init(generation: UInt32) { self.generation = generation }

    static func variant(bold: Bool, italic: Bool, wide: Bool) -> Int {
        (bold ? 1 : 0) | (italic ? 2 : 0) | (wide ? 4 : 0)
    }

    /// The number for a single scalar under `directLimit` in this variant; `unknown` if it was not looked up yet.
    func direct(_ scalar: UInt32, variant: Int) -> UInt32 {
        variant < direct.count && !direct[variant].isEmpty ? direct[variant][Int(scalar)] : Self.unknown
    }

    mutating func setDirect(_ scalar: UInt32, variant: Int, to number: UInt32) {
        if direct.isEmpty { direct = Array(repeating: [], count: 8) }
        if direct[variant].isEmpty {
            direct[variant] = ContiguousArray(repeating: Self.unknown, count: Int(Self.directLimit))
        }
        direct[variant][Int(scalar)] = number
    }

    subscript(key: Key) -> UInt32? {
        get { hashed[key] }
        set { hashed[key] = newValue }
    }

    /// The bitmap of glyph `number` (1 or more).
    subscript(number: UInt32) -> GlyphBitmap { bitmaps[Int(number) - 1] }

    /// Puts `bitmap` in the table; its number, 0 for none.
    mutating func number(_ bitmap: GlyphBitmap?) -> UInt32 {
        guard let bitmap else { return 0 }
        bitmaps.append(bitmap)
        return UInt32(bitmaps.count)
    }

    /// Forgets every glyph and starts a new generation of numbers.
    mutating func startAgain(generation: UInt32) {
        bitmaps.removeAll(keepingCapacity: true)
        hashed.removeAll(keepingCapacity: true)
        direct = []
        self.generation = generation
    }
}
