import Foundation
import SunsetTestSupport
import Testing

/// Roadmap 0109 F (ADR-0109): extensions reach the pages a person browses, nothing else of Sunset's: its windows, settings,
/// documents and Library are native, and its hidden web views (a download's resumer, a probe) are made with no extension
/// controller. Only a page's view is given one, in one place.
@Suite("Where extensions reach")
struct ExtensionReachTests {
    @Test func `only a page's view is given the extensions' controller`() {
        let setters = RepositoryFiles.swiftFiles(in: ["Sources"])
            .filter { $0.text.contains(".webExtensionController =") }
        #expect(setters.map { ($0.name as NSString).lastPathComponent } == ["WebContent+View.swift"])
    }
}
