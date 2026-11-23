import Testing

@testable import SunsetShellModel

/// The sky presets for the welcome and its opening (n143): one for each of the four icons, chosen by the hour of day,
/// matching the icon renderer's parameters (elevation, exposure, pale, burn, airy).
@Suite("Sky presets by time of day")
struct SkyPresetTests {
    @Test func `each preset matches its icon's look and is chosen for its hours of the day`() {
        for (hour, expected) in [
            (0, SkyPreset.dusk), (4, .dusk),
            (5, .dawn), (11, .dawn),
            (12, .sunset), (18, .sunset),
            (19, .twilight), (20, .twilight),
            (21, .dusk), (23, .dusk)
        ] {
            #expect(SkyPreset.forHour(hour) == expected, "hour \(hour)")
        }
        #expect(SkyPreset.sunset.pale == 0 && SkyPreset.sunset.burn == 0 && SkyPreset.sunset.airy == 0)
        #expect(SkyPreset.twilight.pale == 1 && SkyPreset.twilight.burn == 0 && SkyPreset.twilight.airy == 0)
        #expect(SkyPreset.dawn.pale == 1 && SkyPreset.dawn.airy == 1 && SkyPreset.dawn.burn == 0)
        #expect(SkyPreset.dusk.burn == 1 && SkyPreset.dusk.pale == 0 && SkyPreset.dusk.airy == 0)
    }

    @Test func `the opening rises toward the preset's own elevation`() {
        for preset in [SkyPreset.dawn, .sunset, .twilight, .dusk] {
            let start = WelcomeOpening.elevation(at: 0, for: preset)
            let end = WelcomeOpening.elevation(at: .infinity, for: preset)
            #expect(start < end, "\(preset)")
            #expect(abs(end - preset.elevation) < 1e-6, "\(preset)")
        }
    }
}
