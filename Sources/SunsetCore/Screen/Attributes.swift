public struct Attributes: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }

    public static let bold = Attributes(rawValue: 1 << 0)
    public static let faint = Attributes(rawValue: 1 << 1)
    public static let italic = Attributes(rawValue: 1 << 2)
    public static let blink = Attributes(rawValue: 1 << 3)
    public static let inverse = Attributes(rawValue: 1 << 4)
    public static let invisible = Attributes(rawValue: 1 << 5)
    public static let strikethrough = Attributes(rawValue: 1 << 6)
    public static let overline = Attributes(rawValue: 1 << 7)
}
