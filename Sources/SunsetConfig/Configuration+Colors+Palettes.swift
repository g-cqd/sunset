extension Configuration.Colors {
    /// The terminal's colours in the dark scheme: Kitty's 16 ANSI colours (Tomorrow Night's).
    static let kittyAnsi = palette([
        0x1D1F21, 0xCC6666, 0xB5BD68, 0xF0C674, 0x81A2BE, 0xB294B7, 0x8ABEB7, 0xC5C8C6,
        0x666666, 0xD54E53, 0xB9CA4A, 0xE7C557, 0x7AA6DA, 0xC397D8, 0x70C0B1, 0xEAEAEA
    ])

    /// The terminal's colours in light unless changed there: macOS's text (its label colour, black at 85%, over white)
    /// on its text background, and ANSI colours dark enough to read on it (the normal ones at least 4.5:1, the bright ones
    /// 3:1). Tomorrow's hues, as the dark palette is Tomorrow Night's (Kitty's).
    public static let lightForeground: [UInt8] = [0x27, 0x27, 0x27]
    public static let lightBackground: [UInt8] = [0xFF, 0xFF, 0xFF]
    public static let lightAnsi = palette([
        0x1D1F21,
        0xC62828,
        0x3D7A00,
        0x8A6400,
        0x2F62A8,
        0x8A4FAE,
        0x1F7A80,
        0x6E7276,
        0x55585C,
        0xD43A3A,
        0x4A8F0A,
        0xA07800,
        0x3B74C4,
        0x9C5CC2,
        0x22898F,
        0x8A8E92
    ])

    /// Colours written 0xRRGGBB, as red, green, blue.
    static func palette(_ colours: [UInt32]) -> [[UInt8]] {
        colours.map { [UInt8($0 >> 16 & 0xFF), UInt8($0 >> 8 & 0xFF), UInt8($0 & 0xFF)] }
    }
}
