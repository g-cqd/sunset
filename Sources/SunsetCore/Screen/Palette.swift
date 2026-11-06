public struct RGB: Sendable, Equatable {
    public var red: UInt8
    public var green: UInt8
    public var blue: UInt8

    public init(_ red: UInt8, _ green: UInt8, _ blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

/// The colours the program can read and change with OSC 4 and 10-12: the 256-colour palette and the default foreground, background and cursor
/// colours. The host seeds it from the theme; a reset (OSC 104, 110-112) goes back to the seed.
public struct Palette: Sendable, Equatable {
    public internal(set) var colors: ContiguousArray<RGB>
    public internal(set) var foreground: RGB
    public internal(set) var background: RGB
    public internal(set) var cursor: RGB
    private let seed: ContiguousArray<RGB>
    private let seedForeground: RGB
    private let seedBackground: RGB
    private let seedCursor: RGB

    /// xterm's default colours.
    public init() {
        var table = ContiguousArray<RGB>()
        let base: [(UInt8, UInt8, UInt8)] = [
            (0, 0, 0), (205, 0, 0), (0, 205, 0), (205, 205, 0), (0, 0, 238), (205, 0, 205), (0, 205, 205),
            (229, 229, 229),
            (127, 127, 127), (255, 0, 0), (0, 255, 0), (255, 255, 0), (92, 92, 255), (255, 0, 255), (0, 255, 255),
            (255, 255, 255)
        ]
        for color in base { table.append(RGB(color.0, color.1, color.2)) }
        let levels: [UInt8] = [0, 95, 135, 175, 215, 255]
        for red in levels { for green in levels { for blue in levels { table.append(RGB(red, green, blue)) } } }
        for step in 0 ..< 24 {
            let value = UInt8(8 + 10 * step)
            table.append(RGB(value, value, value))
        }
        self.init(colors: table, foreground: RGB(229, 229, 229), background: RGB(0, 0, 0), cursor: RGB(229, 229, 229))
    }

    /// A palette from the host's theme; resets return to these values.
    public init(colors: ContiguousArray<RGB>, foreground: RGB, background: RGB, cursor: RGB) {
        precondition(colors.count == 256, "a palette has 256 colours")
        self.colors = colors
        self.foreground = foreground
        self.background = background
        self.cursor = cursor
        seed = colors
        seedForeground = foreground
        seedBackground = background
        seedCursor = cursor
    }

    mutating func resetColor(_ index: Int) { colors[index] = seed[index] }
    mutating func resetColors() { colors = seed }
    mutating func resetForeground() { foreground = seedForeground }
    mutating func resetBackground() { background = seedBackground }
    mutating func resetCursor() { cursor = seedCursor }

    /// Parses an X colour specification: `rgb:R/G/B` with one to four hex digits per component, or `#RGB`, `#RRGGBB`, `#RRRGGGBBB`, `#RRRRGGGGBBBB`.
    /// No allocation.
    static func parse(_ spec: ArraySlice<UInt8>) -> RGB? {
        func hex(_ digit: UInt8) -> Int? {
            switch digit {
                case 0x30 ... 0x39: Int(digit) - 0x30
                case 0x41 ... 0x46: Int(digit) - 0x41 + 10
                case 0x61 ... 0x66: Int(digit) - 0x61 + 10
                default: nil
            }
        }
        /// The 8-bit value of the `count` hex digits starting at `start`.
        func component(_ start: Int, _ count: Int) -> UInt8? {
            guard (1 ... 4).contains(count) else { return nil }
            var value = 0
            for index in start ..< start + count {
                guard let nibble = hex(spec[index]) else { return nil }
                value = value * 16 + nibble
            }
            // One digit is repeated (f is ff), more are cut to their high eight bits, as X and the terminals that follow it do.
            switch count {
                case 1: return UInt8(value * 17)
                case 2: return UInt8(value)
                case 3: return UInt8(value >> 4)
                default: return UInt8(value >> 8)
            }
        }
        let first = spec.startIndex
        if spec.first == 0x23 {
            let length = spec.count - 1
            guard length > 0, length % 3 == 0 else { return nil }
            let width = length / 3
            guard let red = component(first + 1, width), let green = component(first + 1 + width, width),
                let blue = component(first + 1 + 2 * width, width)
            else { return nil }
            return RGB(red, green, blue)
        }
        guard spec.count > 4, spec[first] == 0x72, spec[first + 1] == 0x67, spec[first + 2] == 0x62,
            spec[first + 3] == 0x3A
        else {
            return nil
        }
        // Three components separated by two slashes.
        var starts = InlineArray<3, Int>(repeating: 0)
        var lengths = InlineArray<3, Int>(repeating: 0)
        var part = 0
        starts[0] = first + 4
        for index in first + 4 ..< spec.endIndex {
            if spec[index] == 0x2F {
                part += 1
                guard part < 3 else { return nil }
                starts[part] = index + 1
            } else {
                lengths[part] += 1
            }
        }
        guard part == 2, let red = component(starts[0], lengths[0]), let green = component(starts[1], lengths[1]),
            let blue = component(starts[2], lengths[2])
        else { return nil }
        return RGB(red, green, blue)
    }
}
