import SunsetConfig
import SunsetCore
import SunsetHost

/// The theme's defaults: the foreground, background and cursor colours (nil keeps the terminal's own), the 16 ANSI colours and the cursor's style.
struct DefaultColors: Sendable, Equatable {
    var foreground: RGB?
    var background: RGB?
    var cursor: RGB?
    /// The 16 ANSI colours; empty keeps the terminal's own.
    var ansi: [RGB] = []
    var cursorShape = CursorShape.block
    var cursorBlinks = true

    init() {}

    init(_ colors: Configuration.Colors, cursorShape shape: Configuration.CursorShape = .block, blinks: Bool = true) {
        cursorShape = CursorShape(shape)
        cursorBlinks = blinks
        func rgb(_ bytes: [UInt8]?) -> RGB? {
            guard let bytes, bytes.count == 3 else { return nil }
            return RGB(bytes[0], bytes[1], bytes[2])
        }
        foreground = rgb(colors.foreground)
        background = rgb(colors.background)
        cursor = rgb(colors.cursor)
        ansi = colors.ansi.compactMap { rgb($0) }
    }
}

extension DefaultColors {
    /// Gives a session these colours: the defaults and the 16 ANSI colours.
    func apply(to session: TerminalSession) async {
        await session.setDefaultColors(foreground: foreground, background: background, cursor: cursor)
        await session.setAnsiColors(ansi)
        await session.setDefaultCursor(shape: cursorShape, blinks: cursorBlinks)
    }
}

extension CursorShape {
    init(_ shape: Configuration.CursorShape) {
        switch shape {
            case .block: self = .block
            case .underline: self = .underline
            case .bar: self = .bar
        }
    }
}
