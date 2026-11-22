import Testing

@testable import SunsetConfig

/// `sidebar.library` and `sidebar.documentSort`. `sidebar.documents`, the heading among the tabs, was a key for a day
/// (2026-11-15): the heading was taken out, and a file that still names it reads without complaint.
@Suite("Configuration: the sections of the sidebar") struct ConfigurationSidebarSectionsTests {
    private func read(_ text: String) throws(ConfigurationError) -> ConfigurationParser.Result {
        try ConfigurationParser.parse(text)
    }

    @Test func `the Library is there unless the file says not, the latest changed first`() throws {
        let sidebar = try read("{}").configuration.sidebar
        #expect(sidebar.library && sidebar.documentSort == .changed)
    }

    @Test func `the file turns the Library off and names the order`() throws {
        let result = try read(#"{ "sidebar": { "library": false, "documentSort": "name" } }"#)
        let sidebar = result.configuration.sidebar
        #expect(result.issues.isEmpty && !sidebar.library && sidebar.documentSort == .name)
        #expect(Configuration.Sidebar.DocumentSort.allCases.map(\.rawValue) == ["changed", "made", "name", "kind"])
    }

    @Test func `a file that still names the heading of a day reads without complaint, and the key is not written`()
        throws
    {
        for value in ["true", "false"] {
            let result = try read(#"{ "sidebar": { "documents": \#(value), "width": 240 } }"#)
            #expect(result.issues.isEmpty && result.configuration.sidebar.width == 240)
        }
        #expect(!ConfigurationKeys.all.contains("sidebar.documents"))
        #expect(ConfigurationWriter.literals(for: Configuration())["sidebar.documents"] == nil)
        #expect(try read(#"{ "sidebar": { "document": true } }"#).issues.map(\.path) == ["sidebar.document"])
    }

    @Test func `an order that is not one is said, and the default is kept`() throws {
        let result = try read(#"{ "sidebar": { "documentSort": "size", "library": "yes" } }"#)
        #expect(result.issues.map(\.path).sorted() == ["sidebar.documentSort", "sidebar.library"])
        #expect(result.configuration.sidebar.documentSort == .changed && result.configuration.sidebar.library)
    }

    @Test func `what is written reads back`() throws {
        var configuration = Configuration()
        configuration.sidebar.library = false
        configuration.sidebar.documentSort = .kind
        let back = try read(ConfigurationWriter.text(for: configuration))
        #expect(back.issues.isEmpty && back.configuration.sidebar == configuration.sidebar)
    }
}
