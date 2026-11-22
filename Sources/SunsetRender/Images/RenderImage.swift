/// An image as the renderers draw it: at the size it is shown, premultiplied by its alpha, packed like `Surface` pixels (red
/// in the lowest byte), rows top to bottom. Made once from what the program sent (`ImageTable`), then only read: a GPU backend
/// uploads it as it is.
public final class RenderImage: Sendable {
    public let width: Int
    public let height: Int
    public let pixels: ContiguousArray<UInt32>

    public init(width: Int, height: Int, pixels: ContiguousArray<UInt32>) {
        precondition(pixels.count == width * height, "one pixel a place")
        self.width = width
        self.height = height
        self.pixels = pixels
    }
}
