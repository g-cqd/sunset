package import AppKit

/// The fourth light's colour (n78; the owner's answer, 2026-11-17): the system's accent, set apart from the three lights'
/// red, amber and green; blue when the accent is near one of them, or has no colour (graphite).
package enum PresetLightColor {
    /// Whether an accent of `hue` and `saturation` (0…1) is far enough from the lights' colours to be the light's.
    /// - Parameters:
    ///   - hue: The accent's hue, red at 0.
    ///   - saturation: Its saturation.
    /// - Returns: False when it is near red, amber, yellow or green, or gray.
    package static func usesAccent(hue: Double, saturation: Double) -> Bool {
        guard saturation >= 0.15 else { return false }
        let nearLights = hue < 0.05 || hue > 0.97 || (0.05 ... 0.45).contains(hue)
        return !nearLights
    }

    /// The light's colour now.
    package static var color: NSColor {
        guard let accent = NSColor.controlAccentColor.usingColorSpace(.sRGB) else { return .systemBlue }
        return usesAccent(hue: accent.hueComponent, saturation: accent.saturationComponent) ? accent : .systemBlue
    }
}
