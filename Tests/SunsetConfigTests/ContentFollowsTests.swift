import Testing

@testable import SunsetConfig

/// `appearance.scheme` forces the app's scheme (macOS's by default); `appearance.contentFollows` makes pages and documents
/// follow it, or macOS's. It replaces `web.pageScheme` (design 0009).
@Suite("The app's scheme and its content's")
struct ContentFollowsTests {
    @Test func `macOS's scheme by default, content following; read, written back, right below the scheme`() throws {
        #expect(Configuration().appearance.scheme == .system && Configuration().appearance.contentFollows)
        let read = try ConfigurationParser.parse(
            #"{ "appearance": { "scheme": "light", "contentFollows": false } }"#
        )
        #expect(read.issues.isEmpty && !read.configuration.appearance.contentFollows)
        let back = try ConfigurationParser.parse(ConfigurationWriter.text(for: read.configuration))
        #expect(back.configuration == read.configuration)
        let ids = SettingsSection.topic("appearance.theme")?.topic.options.map(\.id) ?? []
        #expect(
            ids.firstIndex(of: "appearance.contentFollows") == ids.firstIndex(of: "appearance.scheme").map { $0 + 1 }
        )
    }

    @Test func `web.pageScheme is read as whether content follows, said when it cannot be, and written away`() throws {
        func follows(_ app: String, _ pages: String) throws -> (Bool, Int) {
            let read = try ConfigurationParser.parse(
                #"{ "appearance": { "scheme": "\#(app)" }, "web": { "pageScheme": "\#(pages)" } }"#
            )
            #expect(read.hasFormerValues)
            return (read.configuration.appearance.contentFollows, read.issues.count)
        }
        #expect(try follows("dark", "app") == (true, 0))
        #expect(try follows("dark", "system") == (false, 0))
        #expect(try follows("light", "light") == (true, 0))
        #expect(try follows("dark", "light") == (false, 1), "always light cannot be said: macOS's, and a word")
        let text = #"{ "appearance": { "scheme": "dark" }, "web": { "pageScheme": "system" } }"#
        let upgraded = try #require(ConfigurationPatcher.upgraded(text))
        #expect(!upgraded.contains("pageScheme"))
        let again = try ConfigurationParser.parse(upgraded)
        #expect(!again.hasFormerValues && !again.configuration.appearance.contentFollows && again.issues.isEmpty)
    }
}
