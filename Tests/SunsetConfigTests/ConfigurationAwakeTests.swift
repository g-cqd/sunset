import Testing

@testable import SunsetConfig

/// `tabs.keepAwakeDisplay`: a tab or a window kept awake keeps the Mac from sleeping; whether the display stays on too
/// is this setting ("configurable"). Off by default: the screen may sleep.
@Suite("Configuration: keeping the Mac awake")
struct ConfigurationAwakeTests {
    @Test func `the display may sleep unless the file says otherwise, and the setting is written and read back`() throws
    {
        #expect(try !ConfigurationParser.parse("{}").configuration.tabs.keepAwakeDisplay)
        let on = try ConfigurationParser.parse(#"{ "tabs": { "keepAwakeDisplay": true } }"#)
        #expect(on.issues.isEmpty && on.configuration.tabs.keepAwakeDisplay)
        var configuration = Configuration()
        configuration.tabs.keepAwakeDisplay = true
        let back = try ConfigurationParser.parse(ConfigurationWriter.text(for: configuration))
        #expect(back.issues.isEmpty && back.configuration.tabs.keepAwakeDisplay)
        #expect(ConfigurationKeys.all.contains("tabs.keepAwakeDisplay"))
    }
}
