/// A colour as the terminal was told it: the default, a palette index, or true colour. Packed in 32 bits (tag in the top byte).
public struct Color: Sendable, Hashable {
    let raw: UInt32

    public static let `default` = Color(raw: 0)
    public static func indexed(_ index: UInt8) -> Color { Color(raw: 1 << 24 | UInt32(index)) }
    public static func rgb(_ red: UInt8, _ green: UInt8, _ blue: UInt8) -> Color {
        Color(raw: 2 << 24 | UInt32(red) << 16 | UInt32(green) << 8 | UInt32(blue))
    }

    public var isDefault: Bool { raw == 0 }
    /// The colour as stored (tag in the top byte, then the palette index or the three bytes): for tools that print or compare colours.
    public var packed: UInt32 { raw }
}
