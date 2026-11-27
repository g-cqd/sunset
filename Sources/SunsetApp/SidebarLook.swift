import SunsetConfig

/// What is behind a floating sidebar panel or Now Playing card: the window's settings (blur, glass style, tint),
/// plus `withinWindow` so surfaces floating over a web page or terminal blend against that in-window content rather
/// than what lies behind the window.
struct SidebarLook: Equatable {
    var material: Configuration.Material
    var thickness: Configuration.MaterialThickness
    var glass: Configuration.Appearance.Glass
    var tint: [UInt8]?
    var tintAlpha: Double
    var blur: Double
    var withinWindow: Bool

    init(_ configuration: Configuration, withinWindow: Bool = true) {
        material = configuration.window.material
        thickness = configuration.window.materialThickness
        glass = configuration.appearance.glass
        tint = configuration.appearance.tintColor
        tintAlpha = configuration.appearance.tintAlpha
        blur = configuration.window.blur
        self.withinWindow = withinWindow
    }
}
