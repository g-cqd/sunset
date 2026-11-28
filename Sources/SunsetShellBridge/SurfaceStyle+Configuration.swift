package import SunsetConfig
package import SunsetShell

extension SurfaceStyle {
    /// The surfaces as the configuration says: `window.material`, `appearance.glass`, `appearance.tint`.
    package init(_ configuration: Configuration) {
        let kind: Design.Surface =
            switch configuration.window.material {
                // A colour: the tint, or with none the window's own colour, raised.
                case .color: configuration.appearance.tintColor == nil ? .opaque : .fill
                case .material: .material
                case .glass: .glass
            }
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
