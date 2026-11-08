import SunsetConfig

/// What is behind the floating sidebar panel: the window's own settings (blur, glass style, tint); the sidebar has none of its own.
struct SidebarLook: Equatable {
    var material: Configuration.Material
    var glass: Configuration.Appearance.Glass
    var tint: [UInt8]?
    var tintAlpha: Double
    var blur: Double

    init(_ configuration: Configuration) {
        material = configuration.window.material
        glass = configuration.appearance.glass
        tint = configuration.appearance.tintColor
        tintAlpha = configuration.appearance.tintAlpha
        blur = configuration.window.blur
    }
}
