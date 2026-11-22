@testable import SunsetRender

/// A decoder that reads every file as `image`.
struct StubDecoder: ImageDecoding {
    let image: Surface

    func decodePNG(_ file: [UInt8]) -> DecodedImage? {
        DecodedImage(width: image.width, height: image.height, rgba: image.rgbaBytes)
    }
}
