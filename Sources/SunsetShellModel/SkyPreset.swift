package import Foundation

/// The four skies of the icons (`Design/Icons/RenderIcon.swift`) brought into the live sky shader (`App/SunsetSky.metal`)
/// for the welcome and its opening (n143): chosen by the hour of day, matching the icon's automatic cycle.
package struct SkyPreset: Equatable, Sendable {
    package let elevation: Double
    package let exposure: Double
    package let pale: Double
    package let burn: Double
    package let airy: Double

    package static let sunset = Self(elevation: -0.4, exposure: 0.92, pale: 0, burn: 0, airy: 0)
    package static let twilight = Self(elevation: 0.2, exposure: 0.80, pale: 1, burn: 0, airy: 0)
    package static let dawn = Self(elevation: 0.6, exposure: 0.85, pale: 1, burn: 0, airy: 1)
    package static let dusk = Self(elevation: -3.0, exposure: 0.95, pale: 0, burn: 1, airy: 0)

    /// The sky for the hour of day (0...23): dawn in the morning, sunset in the afternoon, twilight in the evening, dusk
    /// at night (same schedule as `Configuration.Appearance.Icon.forHour`).
    package static func forHour(_ hour: Int) -> Self {
        let normalized = ((hour % 24) + 24) % 24
        if normalized >= 5, normalized < 12 { return .dawn }
        if normalized >= 12, normalized < 19 { return .sunset }
        if normalized >= 19, normalized < 21 { return .twilight }
        return .dusk
    }

    /// The sky for `date` in `calendar`.
    package static func at(_ date: Date, in calendar: Calendar = .current) -> Self {
        forHour(calendar.component(.hour, from: date))
    }
}
