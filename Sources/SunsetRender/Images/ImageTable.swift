internal import SunsetCore

/// The images a renderer has made ready to draw, by number (`DrawFrame.images`; a draw operation names one as
/// `DrawOp.imageMark | number`), each made once for an image at a size. As the glyph table: a number keeps its image while
/// `generation` stays the same, so a backend can keep its uploads by number; it starts again, under a new generation, when it
/// holds more than the renderer allows.
struct ImageTable {
    private struct Key: Hashable {
        let id: UInt32
        /// Which of the images sent under that number: a program sends a new one under the same number.
        let order: UInt64
        let source: ImageCrop
        let width: Int
        let height: Int
    }

    private(set) var images: ContiguousArray<RenderImage> = []
    private var numbers: [Key: UInt32] = [:]
    /// Images that did not read, so that they are not read again at every frame.
    private var unreadable: Set<Key> = []
    private(set) var bytes = 0
    private(set) var generation: UInt32

    init(generation: UInt32) {
        self.generation = generation
    }

    /// The number of `source` of `image` at `width` × `height`, made the first time; nil when it does not read.
    mutating func number(
        of image: TerminalImage,
        source: ImageCrop,
        width: Int,
        height: Int,
        decoder: (any ImageDecoding)?
    ) -> UInt32? {
        let key = Key(id: image.id, order: image.order, source: source, width: width, height: height)
        if let number = numbers[key] { return number }
        guard !unreadable.contains(key) else { return nil }
        guard let made = RenderImage.make(image, source: source, width: width, height: height, decoder: decoder) else {
            unreadable.insert(key)
            return nil
        }
        let number = UInt32(images.count)
        images.append(made)
        numbers[key] = number
        bytes += made.pixels.count * 4
        return number
    }

    /// Forgets every image and starts a new generation of numbers.
    mutating func startAgain(generation: UInt32) {
        images.removeAll()
        numbers.removeAll()
        unreadable.removeAll()
        bytes = 0
        self.generation = generation
    }
}
