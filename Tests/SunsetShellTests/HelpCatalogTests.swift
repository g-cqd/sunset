import Foundation
import Testing

@testable import SunsetHelp

/// Help's texts (roadmap 0041 A; research help-system-from-vmrunner-2026-11-17): one source for a control's tooltip and its
/// explanation. Every topic has its text, a summary is one short sentence (it is the tooltip), titles are unique, related
/// topics exist, every area has topics.
@Suite("Help's texts")
struct HelpCatalogTests {
    @Test func `every topic has its text, and every area its topics`() {
        let missing = HelpTopic.allCases.filter { HelpCatalog.entries[$0] == nil }
        #expect(missing.isEmpty, "\(missing)")
        let empty = HelpArea.allCases.filter { area in !HelpTopic.allCases.contains { $0.area == area } }
        #expect(empty.isEmpty, "\(empty)")
        let blank = HelpTopic.allCases.filter { HelpCatalog.entry($0).text.isEmpty }
        #expect(blank.isEmpty, "\(blank)")
    }

    @Test func `a summary is one sentence of at most 110 characters`() {
        let found = HelpTopic.allCases.map(HelpCatalog.entry)
            .filter { entry in
                entry.summary.count > 110 || !entry.summary.hasSuffix(".") || entry.summary.dropLast().contains(". ")
            }
        #expect(found.isEmpty, "\(found.map(\.summary))")
    }

    @Test func `titles are unique, and related topics are others`() {
        let titles = HelpTopic.allCases.map { HelpCatalog.entry($0).title }
        #expect(Set(titles).count == titles.count)
        let selfRelated = HelpTopic.allCases.filter { HelpCatalog.entry($0).related.contains($0) }
        #expect(selfRelated.isEmpty, "\(selfRelated)")
    }

    @Test func `search finds a topic by every word of the query, in any case`() {
        #expect(HelpCatalog.search("keep AWAKE").contains(.keepAwake))
        #expect(HelpCatalog.search("awake folder nothing-like-this").isEmpty)
        #expect(HelpCatalog.search("").count == HelpTopic.allCases.count)
    }
}
