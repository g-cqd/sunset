/// An image a program sent (ADR-0117): its pixels as sent (RGB or RGBA, eight bits a channel, rows top to bottom), or a
/// PNG file kept encoded, its size read from its header; the renderer decodes it. Optional Kitty animation state tracks
/// extra frames (`a=f`), composition (`a=c`), and playback control (`a=a`).
public struct TerminalImage: Sendable, Equatable {
    public enum Format: Sendable, Equatable {
        case rgb, rgba, png
    }

    public let id: UInt32
    /// Optional Kitty image number (`I=`): multiple images may share a number; the newest with that number is referenced.
    public let number: UInt32
    public let format: Format
    public let width: Int
    public let height: Int
    /// The pixels (`rgb`, `rgba`), or the PNG file (`png`).
    public let pixels: [UInt8]
    /// When it was stored, among the terminal's images: the oldest go first when the quota is reached.
    public let order: UInt64
    /// Optional animation frames and playback state (Kitty `a=f`, `a=a`, `a=c`).
    public var animation: ImageAnimation?

    public init(
        id: UInt32,
        number: UInt32 = 0,
        format: Format,
        width: Int,
        height: Int,
        pixels: [UInt8],
        order: UInt64,
        animation: ImageAnimation? = nil
    ) {
        self.id = id
        self.number = number
        self.format = format
        self.width = width
        self.height = height
        self.pixels = pixels
        self.order = order
        self.animation = animation
    }

    /// Total byte cost accounted against `TerminalGraphics.quota` (root payload plus any extra animation frames).
    public var byteCount: Int {
        pixels.count + (animation?.extraBytes ?? 0)
    }

    /// The image currently active for rendering (either the root image or the selected animation frame, with a distinct
    /// order token, its revision, so `ImageTable` caches each displayed frame, and each edit of it, separately).
    public var activeForRender: TerminalImage {
        guard let frame = animation?.activeExtraFrame else { return self }
        return TerminalImage(
            id: id,
            number: number,
            format: .rgba,
            width: frame.width,
            height: frame.height,
            pixels: frame.rgba,
            order: frame.revision
        )
    }
}
