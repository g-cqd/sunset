/// The colour a person gives a symbol icon (R3: any colour, on tabs, entries and folders): sRGB, 8 bits a channel. Saved as `#RRGGBB`.
public struct IconColor: Sendable, Equatable, Hashable {
    public let red: UInt8
    public let green: UInt8
    public let blue: UInt8

    public init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    /// `#RRGGBB` (the `#` optional, case ignored); nil for anything else.
    public init?(hex: String) {
        let digits = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard digits.count == 6, digits.allSatisfy(\.isHexDigit), let value = UInt32(digits, radix: 16) else {
            return nil
        }
        self.init(red: UInt8(value >> 16 & 0xFF), green: UInt8(value >> 8 & 0xFF), blue: UInt8(value & 0xFF))
    }

    public var hex: String {
        let digits = [red, green, blue].map { String($0, radix: 16, uppercase: true) }
            .map { $0.count == 1 ? "0" + $0 : $0 }
        return "#" + digits.joined()
    }
}
