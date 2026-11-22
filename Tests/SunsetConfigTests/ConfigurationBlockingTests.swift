import Testing

@testable import SunsetConfig

/// Blocking is on by default with EasyList and EasyPrivacy; lists are https addresses, others are said and left out; in
/// Settings > Web > Blocking.
@Suite("Blocking: the settings")
struct ConfigurationBlockingTests {
    @Test func `on with two lists by default; https lists only; read, written and in Settings`() throws {
        let plain = try ConfigurationParser.parse("{}").configuration.web
        #expect(plain.blocking && plain.blockingLists == Configuration.Web.defaultBlockingLists)
        #expect(plain.blockingLists.count == 2 && plain.blockingLists.allSatisfy { $0.hasPrefix("https://") })
        let file =
            #"{ "web": { "blocking": false, "blockingLists": ["https://a.example/list.txt", "http://b.example/x", 3] } }"#
        let other = try ConfigurationParser.parse(file)
        #expect(!other.configuration.web.blocking)
        #expect(other.configuration.web.blockingLists == ["https://a.example/list.txt"])
        #expect(other.issues.count == 2, "a list over plain http, and one that is not an address")
        let back = try ConfigurationParser.parse(ConfigurationWriter.text(for: other.configuration))
        #expect(back.issues.isEmpty && back.configuration.web == other.configuration.web)
        #expect(SettingsSection.topic("web.blocking")?.topic.options.map(\.id) == ["web.blocking", "web.blockingLists"])
    }
}
