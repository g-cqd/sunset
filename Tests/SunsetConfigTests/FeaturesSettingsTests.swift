import Testing

@testable import SunsetConfig

/// `features.terminal`, `features.web`, `features.documents` (roadmap 0033): each removes a scope of the app; all on by
/// default; at least one stays on.
@Suite("The scopes of the app, in the settings")
struct FeaturesSettingsTests {
    @Test func `all on by default; each can be turned off in the file, and is written back`() throws {
        let plain = Configuration().features
        #expect(plain.terminal && plain.web && plain.documents)
        let set = try ConfigurationParser.parse(#"{ "features": { "web": false, "documents": false } }"#)
        #expect(set.issues.isEmpty)
        #expect(set.configuration.features == .init(terminal: true, web: false, documents: false))
        let again = try ConfigurationParser.parse(ConfigurationWriter.text(for: set.configuration))
        #expect(again.configuration.features == set.configuration.features)
        let bad = try ConfigurationParser.parse(#"{ "features": { "web": "no", "games": true } }"#)
        #expect(Set(bad.issues.map(\.path)) == ["features.web", "features.games"] && bad.configuration.features.web)
    }

    @Test func `all three off in the file is said, and terminals stay`() throws {
        let none = try ConfigurationParser.parse(
            #"{ "features": { "terminal": false, "web": false, "documents": false } }"#
        )
        #expect(none.issues.map(\.path) == ["features"])
        #expect(none.configuration.features == .init(terminal: true, web: false, documents: false))
    }

    @Test func `the settings of a scope that is off are not shown; the switches always are`() {
        var features = Configuration.Features()
        #expect(SettingsSection.sections(for: features).map(\.id) == SettingsSection.all.map(\.id))
        #expect(SettingsSection.general.topics.map(\.id).first == "general.features")
        features.web = false
        let noWeb = SettingsSection.sections(for: features)
        #expect(!noWeb.map(\.id).contains("web") && noWeb.map(\.id).contains("terminal"))
        #expect(!noWeb.flatMap(\.topics).map(\.id).contains("privacy.browsing"))
        features = .init(terminal: false, web: true, documents: false)
        let webOnly = SettingsSection.sections(for: features)
        #expect(!webOnly.map(\.id).contains("terminal") && webOnly.map(\.id).contains("web"))
        #expect(!webOnly.flatMap(\.topics).map(\.id).contains("general.documents"))
        #expect(!webOnly.flatMap(\.topics).map(\.id).contains("privacy.programs"))
        #expect(webOnly.flatMap(\.topics).map(\.id).contains("general.features"))
    }
}
