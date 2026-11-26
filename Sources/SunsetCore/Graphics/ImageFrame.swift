/// One frame of a Kitty animated image beyond the root (`a=f` — roadmap 0010 E), its pixels composed onto the root's
/// canvas size.
public struct ImageFrame: Sendable, Equatable {
    /// 1-based frame number within the image (frame 1 is the root image itself, so this is 2 or more).
    public let index: Int
    /// Milliseconds before the next frame shows while the animation runs; negative: a gapless frame, never shown.
    public var gapMilliseconds: Int
    public let width: Int
    public let height: Int
    /// Straight RGBA, `width * height * 4` bytes.
    public var rgba: [UInt8]
    /// Changes whenever the pixels do (a value of `TerminalGraphics.nextOrder()`): the renderer's image cache is keyed
    /// by it, so a frame edited in place is never drawn from a stale copy.
    public var revision: UInt64

    public init(index: Int, gapMilliseconds: Int, width: Int, height: Int, rgba: [UInt8], revision: UInt64) {
        self.index = index
        self.gapMilliseconds = gapMilliseconds
        self.width = width
        self.height = height
        self.rgba = rgba
        self.revision = revision
    }
}
