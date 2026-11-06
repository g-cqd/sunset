import SunsetConfig
import SunsetCore

/// The default foreground, background and cursor colours of the theme; nil keeps the terminal's own.
struct DefaultColors: Sendable, Equatable {
    var foreground: RGB?
    var background: RGB?
    var cursor: RGB?

    init() {}

    init(_ colors: Configuration.Colors) {
        func rgb(_ bytes: [UInt8]?) -> RGB? {
            guard let bytes, bytes.count == 3 else { return nil }
            return RGB(bytes[0], bytes[1], bytes[2])
        }
        foreground = rgb(colors.foreground)
        background = rgb(colors.background)
        cursor = rgb(colors.cursor)
    }
}
