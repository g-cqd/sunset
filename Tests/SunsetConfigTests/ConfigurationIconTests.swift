import Testing

@testable import SunsetConfig

/// Choosing among the four icons built (`App/<Name>.icon`, the first the bundle's own, the other three alternates in
/// the same asset catalog).
@Suite("Configuration: the app's icon")
struct ConfigurationIconTests {
    @Test func `Sunset by default; Twilight, Dawn and Dusk chosen, written and read back`() throws {
        #expect(try ConfigurationParser.parse("{}").configuration.appearance.icon == .sunset)
        #expect(Configuration.Appearance.Icon.allCases.map(\.assetName) == ["Sunset", "Twilight", "Dawn", "Dusk"])
        for icon in Configuration.Appearance.Icon.allCases {
            var chosen = Configuration()
            chosen.appearance.icon = icon
            let back = try ConfigurationParser.parse(ConfigurationWriter.text(for: chosen))
            #expect(back.issues.isEmpty && back.configuration.appearance.icon == icon)
        }
        let read = try ConfigurationParser.parse(#"{"appearance":{"icon":"dusk"}}"#)
        #expect(read.configuration.appearance.icon == .dusk)
        #expect(!(try ConfigurationParser.parse(#"{"appearance":{"icon":"noon"}}"#).issues.isEmpty))
        #expect(ConfigurationKeys.all.contains("appearance.icon") && SettingsOption.named("appearance.icon") != nil)
    }
}
