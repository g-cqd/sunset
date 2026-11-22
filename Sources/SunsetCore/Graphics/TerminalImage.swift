/// An image a program sent (ADR-0117): its pixels as sent (RGB or RGBA, eight bits a channel, rows top to bottom), or a
/// PNG file kept encoded, its size read from its header; the renderer decodes it.
public struct TerminalImage: Sendable, Equatable {
    public enum Format: Sendable, Equatable {
        case rgb, rgba, png
    }

    public let id: UInt32
    public let format: Format
    public let width: Int
    public let height: Int
    /// The pixels (`rgb`, `rgba`), or the PNG file (`png`).
    public let pixels: [UInt8]
    /// When it was stored, among the terminal's images: the oldest go first when the quota is reached.
    public let order: UInt64
}
