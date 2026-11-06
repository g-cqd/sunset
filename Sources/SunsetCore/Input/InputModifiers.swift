/// Modifier keys held with a key press. (Command is the host's: it never reaches the program.)
public struct InputModifiers: OptionSet, Sendable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }

    public static let shift = InputModifiers(rawValue: 1 << 0)
    public static let option = InputModifiers(rawValue: 1 << 1)
    public static let control = InputModifiers(rawValue: 1 << 2)
}
