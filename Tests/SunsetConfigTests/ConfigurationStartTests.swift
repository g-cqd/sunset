import Testing

@testable import SunsetConfig

/// The owner's note n74: Sunset opening with no tab is empty unless set to open a kind of tab, an address, a document
/// file or a new document, in a profile or the last one.
@Suite("Configuration: what opens with no tab")
struct ConfigurationStartTests {
    @Test func `nothing by default; each choice, the address, the file and the profile read, written and offered`()
        throws
    {
        let empty = try ConfigurationParser.parse("{}").configuration.tabs
        #expect(empty.start == .nothing && empty.startAddress.isEmpty && empty.startFile.isEmpty)
        #expect(empty.startProfile.isEmpty)
        for variant in Configuration.Tabs.Start.allCases {
            var configuration = Configuration()
            configuration.tabs.start = variant
            configuration.tabs.startAddress = "https://example.com/"
            configuration.tabs.startFile = "~/Notes/today.md"
            configuration.tabs.startProfile = "Work"
            let back = try ConfigurationParser.parse(ConfigurationWriter.text(for: configuration))
            #expect(back.issues.isEmpty && back.configuration.tabs == configuration.tabs)
        }
        for id in ["tabs.start", "tabs.startAddress", "tabs.startFile", "tabs.startProfile"] {
            #expect(SettingsOption.named(id) != nil, "\(id)")
        }
    }
}
