/// An image file's pixels as `ImageDecoding` gives them: RGBA, eight bits a channel, premultiplied by the alpha, rows top to
/// bottom, `width` × `height` × 4 bytes.
public struct DecodedImage: Sendable {
    public let width: Int
    public let height: Int
    public let rgba: [UInt8]

    public init(width: Int, height: Int, rgba: [UInt8]) {
        precondition(rgba.count == width * height * 4, "four bytes a pixel")
        self.width = width
        self.height = height
        self.rgba = rgba
    }
}
