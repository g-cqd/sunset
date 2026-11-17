import Testing

@testable import SunsetHelp

/// A setting with a topic shows a "?" beside it (roadmap 0041 C).
@Suite("Help beside settings")
struct HelpSettingsTests {
    @Test func `a setting is explained by its topic, and one without none`() {
        #expect(HelpTopic.explaining(setting: "tabs.keepAwakeDisplay") == .keepAwake)
        #expect(HelpTopic.explaining(setting: "font.size") == nil)
    }
}
