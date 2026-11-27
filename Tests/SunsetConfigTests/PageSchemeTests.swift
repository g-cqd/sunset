import Testing

@testable import SunsetConfig

/// `web.pageScheme`: the pages' scheme, apart from Sunset's own (design 0009).
@Suite("The pages' scheme")
struct PageSchemeTests {
    @Test func `Sunset's own by default; read and written back; in Web › Pages`() throws {
        #expect(Configuration().web.pageScheme == .app)
        let read = try ConfigurationParser.parse(
            #"{ "appearance": { "scheme": "light" }, "web": { "pageScheme": "dark" } }"#
        )
        #expect(read.issues.isEmpty)
        #expect(read.configuration.web.pageScheme == .dark && read.configuration.appearance.scheme == .light)
        let back = try ConfigurationParser.parse(ConfigurationWriter.text(for: read.configuration))
        #expect(back.configuration.web.pageScheme == .dark)
        #expect(SettingsSection.topic("web.pages")?.topic.options.contains { $0.id == "web.pageScheme" } == true)
    }
}
