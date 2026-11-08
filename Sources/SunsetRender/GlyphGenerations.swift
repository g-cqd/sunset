internal import Synchronization

/// Hands out glyph table generations (`DrawFrame.glyphGeneration`), unique in the process, so that a backend never mistakes one renderer's glyph numbers for
/// another's. Starts at 1: 0 is left for frames made by hand.
enum GlyphGenerations {
    private static let counter = Atomic<UInt32>(0)

    static func next() -> UInt32 {
        counter.wrappingAdd(1, ordering: .relaxed).newValue
    }
}
