/// The platform seam that reads image files for the renderer (ADR-0117): the core keeps a PNG as it was sent, and the renderer
/// asks this to read it once, when it is first shown. ImageIO on macOS (`ImageIODecoder`, SunsetRenderMac).
public protocol ImageDecoding: Sendable {
    /// A PNG file's pixels, or nil when it does not read.
    func decodePNG(_ file: [UInt8]) -> DecodedImage?
}
