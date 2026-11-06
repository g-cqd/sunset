/// A frame drawn by a renderer, as bytes a presenter can hand to the display: `width` x `height` pixels, red, green, blue, alpha.
public struct RenderedFrame: Sendable {
    public let width: Int
    public let height: Int
    public let bytes: [UInt8]

    public init(width: Int, height: Int, bytes: [UInt8]) {
        self.width = width
        self.height = height
        self.bytes = bytes
    }
}
