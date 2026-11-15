import Testing

@testable import SunsetConfig

/// `sidebar.library`, `sidebar.documents` and `sidebar.documentSort` (roadmap 0031, 0030 step ST-5).
@Suite("Configuration: the sections of the sidebar") struct ConfigurationSidebarSectionsTests {
    private func read(_ text: String) throws(ConfigurationError) -> ConfigurationParser.Result {
        try ConfigurationParser.parse(text)
    }

    @Test func `the Library and the Documents heading are there unless the file says not, the latest changed first`()
        throws
    {
        let sidebar = try read("{}").configuration.sidebar
        #expect(sidebar.library && sidebar.documents && sidebar.documentSort == .changed)
    }

    @Test func `the file turns each off by itself and names the order`() throws {
        let result = try read(#"{ "sidebar": { "library": false, "documents": false, "documentSort": "name" } }"#)
        let sidebar = result.configuration.sidebar
        #expect(result.issues.isEmpty && !sidebar.library && !sidebar.documents && sidebar.documentSort == .name)
        let one = try read(#"{ "sidebar": { "library": false } }"#).configuration.sidebar
        #expect(!one.library && one.documents, "neither depends on the other")
        #expect(Configuration.Sidebar.DocumentSort.allCases.map(\.rawValue) == ["changed", "made", "name", "kind"])
    }

    @Test func `an order that is not one is said, and the default is kept`() throws {
        let result = try read(#"{ "sidebar": { "documentSort": "size", "library": "yes" } }"#)
        #expect(result.issues.map(\.path).sorted() == ["sidebar.documentSort", "sidebar.library"])
        #expect(result.configuration.sidebar.documentSort == .changed && result.configuration.sidebar.library)
    }

    @Test func `what is written reads back`() throws {
        var configuration = Configuration()
        configuration.sidebar.library = false
        configuration.sidebar.documents = false
        configuration.sidebar.documentSort = .kind
        let back = try read(ConfigurationWriter.text(for: configuration))
        #expect(back.issues.isEmpty && back.configuration.sidebar == configuration.sidebar)
    }
}
