import SunsetConfig

/// What is behind the sidebar, from the configuration.
struct SidebarLook: Equatable {
    var material: Configuration.Material
    var glass: Configuration.Appearance.Glass
    var tint: [UInt8]?
    var tintAlpha: Double
    var blur: Double

    init(_ configuration: Configuration) {
        material = configuration.sidebar.material
        glass = configuration.appearance.glass
        tint = configuration.appearance.tintColor
        tintAlpha = configuration.appearance.tintAlpha
        blur = configuration.sidebar.blur
    }
}
