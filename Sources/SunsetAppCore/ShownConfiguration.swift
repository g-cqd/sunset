package import SunsetConfig

/// The configuration the windows are drawn with (`AppConfiguration` made it in the app target): each look setting's value
/// in the scheme the app is drawn in (design 0009).
package enum ShownConfiguration {
    package static func make(_ configuration: Configuration, light: Bool) -> Configuration {
        configuration.inScheme(light: light)
    }
}
