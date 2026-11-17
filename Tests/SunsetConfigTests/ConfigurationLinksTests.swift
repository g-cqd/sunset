import Testing

@testable import SunsetConfig

/// `documents.linksOpen` (the owner, 2026-11-17: a link in a rendered document opened in a split, "a setting"): where a
/// plain click on a document's link opens it. In a new tab by default, as a browser; or beside the document.
@Suite("Configuration: where a document's links open")
struct ConfigurationLinksTests {
    @Test func `a new tab unless the file says beside; written and read back; listed`() throws {
        #expect(try ConfigurationParser.parse("{}").configuration.documents.linksOpen == .tab)
        let beside = try ConfigurationParser.parse(#"{ "documents": { "linksOpen": "beside" } }"#)
        #expect(beside.issues.isEmpty && beside.configuration.documents.linksOpen == .beside)
        var configuration = Configuration()
        configuration.documents.linksOpen = .beside
        let back = try ConfigurationParser.parse(ConfigurationWriter.text(for: configuration))
        #expect(back.configuration.documents.linksOpen == .beside)
        #expect(ConfigurationKeys.all.contains("documents.linksOpen"))
    }
}
