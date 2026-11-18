import AppKit
import SunsetConfig
import SunsetPane

/// What is behind a window's terminal, as the configuration says: a material, glass, nothing (with a blur radius), and the tint over it.
struct WindowLook: Equatable {
    var material = Configuration.Material.opaque
    var thickness = Configuration.MaterialThickness.regular
    var glass = Configuration.Appearance.Glass.regular
    var tint: [UInt8]?
    var tintAlpha = 0.25
    var blur = 0.0
    var scheme = Configuration.Appearance.Scheme.dark
    /// The app is drawn light now: the tint is laid over regular glass as a view (measured 2026-11-13: regular glass ignores its
    /// `tintColor`, and turns dark over a dark desktop whatever the window's appearance, under the scheme's black text).
    var light = false

    init() {}

    init(_ configuration: Configuration, light: Bool = false) {
        self.light = light
        material = configuration.window.material
        thickness = configuration.window.materialThickness
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

    /// The same look with a Space's colour in its tint: a third of it mixed into the window's own tint, so that the window
    /// is tinted and not painted (text must still read on it). A window with no tint of its own takes the colour as its
    /// tint, as faint as a tint is by default.
    func tinted(by color: IconColor?) -> WindowLook {
        guard let color else { return self }
        var look = self
        if let tint, tint.count == 3, tintAlpha > 0 {
            look.tint = color.mixed(into: tint, share: Self.spaceShare)
        } else {
            look.tint = [color.red, color.green, color.blue]
            look.tintAlpha = 0.25
        }
        return look
    }

    static let spaceShare = 1.0 / 3

    var isOpaque: Bool { material == .opaque }
}
