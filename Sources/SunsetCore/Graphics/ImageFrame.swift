/// Animation frame metadata for Kitty graphics animation (`a=f`, `a=a`, `a=c` — roadmap 0010 E).
public struct ImageFrame: Sendable, Equatable {
    /// 1-based frame index within the image (frame 1 is the root image itself).
    public let index: Int
    /// Delay before advancing to the next frame in milliseconds (`z`, default 40 ms when 0; negative means gapless).
    public var gapMilliseconds: Int
    /// Frame dimensions in pixels (always matches root image canvas after composition).
    public let width: Int
    public let height: Int
    /// Straight RGBA pixel buffer (`width * height * 4` bytes).
    public var rgba: [UInt8]

    public init(index: Int, gapMilliseconds: Int, width: Int, height: Int, rgba: [UInt8]) {
        self.index = index
        self.gapMilliseconds = gapMilliseconds
        self.width = width
        self.height = height
        self.rgba = rgba
    }
}
