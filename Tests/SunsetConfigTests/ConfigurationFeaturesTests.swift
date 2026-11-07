import Testing

@testable import SunsetConfig

@Suite("Configuration: font features and keyboard") struct ConfigurationFeaturesTests {
    @Test func `font features and option-as-meta are read, with defaults of none and off`() throws {
        let defaults = try ConfigurationParser.parse("{}").configuration
        #expect(defaults.font.features.isEmpty && !defaults.keyboard.optionAsMeta)
        let set = try ConfigurationParser.parse(
            #"{ "font": { "features": "zero, ss01" }, "keyboard": { "optionAsMeta": true } }"#
        )
        #expect(set.issues.isEmpty)
        #expect(set.configuration.font.features == "zero, ss01")
        #expect(set.configuration.keyboard.optionAsMeta)
    }

    @Test func `a wrong keyboard value is reported with its path`() throws {
        let result = try ConfigurationParser.parse(#"{ "keyboard": { "optionAsMeta": "yes", "layout": 1 } }"#)
        #expect(result.issues.map(\.path).sorted() == ["keyboard.layout", "keyboard.optionAsMeta"])
    }

    @Test func `a keyboard or features change is its own group`() {
        var new = Configuration()
        new.keyboard.optionAsMeta = true
        #expect(new.changes(from: Configuration()) == [.keyboard])
        var features = Configuration()
        features.font.features = "zero"
        #expect(features.changes(from: Configuration()) == [.font])
    }
}
