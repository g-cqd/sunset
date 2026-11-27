package import SwiftUI

/// What is behind the content of a pane: the terminal's default background (the theme's `colors.background`, black with none)
/// as opaque as the terminal draws it (`terminal.opacity` over a window that is not opaque). A terminal draws it itself; every
/// other kind of pane is drawn on it, so that a window's panes are one surface whatever is in them.
package struct PaneBackdrop: Sendable, Equatable {
    package var red: UInt8
    package var green: UInt8
    package var blue: UInt8
    /// 1 is opaque.
    package var alpha: Double

    /// The terminal's own background, when the theme names none.
    package static let black = Self(red: 0, green: 0, blue: 0, alpha: 1)

    package init(red: UInt8, green: UInt8, blue: UInt8, alpha: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// From the configuration's three bytes; nil, or not three, is the terminal's black.
    package init(rgb: [UInt8]?, alpha: Double) {
        if let rgb, rgb.count == 3 {
            self.init(red: rgb[0], green: rgb[1], blue: rgb[2], alpha: alpha)
        } else {
            self.init(red: 0, green: 0, blue: 0, alpha: alpha)
        }
    }

    /// As a terminal is seen with its background at `terminalAlpha` of 255. A terminal has that background twice, one over the
    /// other: the colour of its view's layer and the pixels of its frame. Composed once, a document was lighter than the
    /// terminal next to it (35 for 27 over the window's 44 with `terminal.opacity` 0.2).
    package init(rgb: [UInt8]?, terminalAlpha: UInt8) {
        let through = 1 - Double(terminalAlpha) / 255
        self.init(rgb: rgb, alpha: 1 - through * through)
    }

    package var color: Color {
        Color(.sRGB, red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255, opacity: alpha)
    }

    /// By its luminance (Rec. 709), as the window's light tint is decided.
    package var isDark: Bool {
        0.2126 * Double(red) + 0.7152 * Double(green) + 0.0722 * Double(blue) < 128
    }

    /// For the app's own pages (Settings, Help, Passwords), which follow Sunset's scheme and not the terminal's theme: the
    /// terminal's background when it is of that scheme, else a neutral one of it, as opaque.
    package func forApp(light: Bool) -> Self {
        guard isDark == light else { return self }
        return light
            ? Self(red: 0xF5, green: 0xF5, blue: 0xF7, alpha: alpha)
            : Self(red: 0x1E, green: 0x1E, blue: 0x20, alpha: alpha)
    }

    /// The scheme text is read in over it: the window may be light around a dark terminal, and its labels would be dark on dark.
    package var scheme: ColorScheme {
        isDark ? .dark : .light
    }
}

extension View {
    /// Draws a pane's content on the terminal's background, in the scheme that is read on it.
    package func paneBackdrop(_ backdrop: PaneBackdrop) -> some View {
        environment(\.colorScheme, backdrop.scheme).background(backdrop.color)
    }
}
