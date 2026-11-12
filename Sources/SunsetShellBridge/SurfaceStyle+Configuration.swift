package import SunsetConfig
package import SunsetShell

extension SurfaceStyle {
    /// The surfaces as the configuration says: `window.material`, `appearance.glass`, `appearance.tint`.
    package init(_ configuration: Configuration) {
        let kind = Design.Surface(rawValue: configuration.window.material.rawValue) ?? .glass
        let tint = configuration.appearance.tintColor.flatMap { rgb -> [Double]? in
            guard rgb.count == 3 else { return nil }
            return rgb.map { Double($0) / 255 } + [configuration.appearance.tintAlpha]
        }
        self.init(
            kind: kind,
            clearGlass: configuration.appearance.glass == .clear,
            tint: tint,
            layout: configuration.layout
        )
    }
}
