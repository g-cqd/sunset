import AppKit
import SunsetConfig

/// What is behind a window's terminal, as the configuration says: a material, glass, nothing (with a blur radius), and the tint over it.
struct WindowLook: Equatable {
    var material = Configuration.Material.opaque
    var glass = Configuration.Appearance.Glass.regular
    var tint: [UInt8]?
    var tintAlpha = 0.25
    var blur = 0.0
    var scheme = Configuration.Appearance.Scheme.dark

    init() {}

    init(_ configuration: Configuration) {
        material = configuration.window.material
        glass = configuration.appearance.glass
        tint = configuration.appearance.tintColor
        tintAlpha = configuration.appearance.tintAlpha
        blur = configuration.window.blur
        scheme = configuration.appearance.scheme
    }

    /// The tint as a colour (sRGB, with its alpha), or nil for none.
    var tintColor: NSColor? {
        guard let tint, tint.count == 3, tintAlpha > 0 else { return nil }
        return NSColor(
            srgbRed: Double(tint[0]) / 255,
            green: Double(tint[1]) / 255,
            blue: Double(tint[2]) / 255,
            alpha: tintAlpha
        )
    }

    var isOpaque: Bool { material == .opaque }
}
