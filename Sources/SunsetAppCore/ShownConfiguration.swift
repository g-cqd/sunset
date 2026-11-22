package import SunsetConfig

/// The configuration the windows are drawn with (`AppConfiguration` made it in the app target): in the light scheme the
/// light tint, and a dark terminal theme opaque over it.
package enum ShownConfiguration {
    package static func make(_ configuration: Configuration, light: Bool) -> Configuration {
        guard light else { return configuration }
        var shown = configuration
        shown.appearance.tintColor = configuration.appearance.lightTintColor
        shown.appearance.tintAlpha = configuration.appearance.lightTintAlpha
        // A dark terminal theme keeps its own background over the light tint: translucent, it washed out to grey under light text.
        if isDark(configuration.colors.background) { shown.terminal.opacity = 1 }
        return shown
    }

    /// A colour is dark (by its luma); none counts as dark (the terminal's default is black).
    package static func isDark(_ colour: [UInt8]?) -> Bool {
        guard let colour, colour.count == 3 else { return true }
        return 0.2126 * Double(colour[0]) + 0.7152 * Double(colour[1]) + 0.0722 * Double(colour[2]) < 128
    }
}
