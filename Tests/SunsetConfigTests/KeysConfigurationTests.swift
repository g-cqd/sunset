import Testing

@testable import SunsetConfig

/// `keys`: the commands' keys, read and written as an object of strings.
@Suite("The keys section")
struct KeysConfigurationTests {
    @Test func `read as an object of strings; anything else is said`() throws {
        let read = try ConfigurationParser.parse(#"{ "keys": { "splitRight": "cmd+e", "splitDown": 3 } }"#)
        #expect(read.configuration.keys == ["splitRight": "cmd+e"])
        #expect(read.issues.map(\.path) == ["keys.splitDown"])
    }

    @Test func `written back as it was read`() throws {
        var configuration = Configuration()
        configuration.keys = ["splitRight": "cmd+e", "newTab": ""]
        let text = ConfigurationWriter.text(for: configuration)
        #expect(try ConfigurationParser.parse(text).configuration.keys == configuration.keys)
    }
}
