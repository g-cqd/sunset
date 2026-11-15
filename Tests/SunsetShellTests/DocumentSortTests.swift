import Foundation
import Testing

@testable import SunsetShell

/// The orders of the documents (the owner, 2026-11-15: Latest Changed, the default; Latest Made; Name; Kind), and their groups.
@Suite("The order of the documents") struct DocumentSortTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()
    var now: Date { date(15, 12) }

    func date(_ day: Int, _ hour: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour)) ?? .distantPast
    }

    var documents: [ShelfDocument] {
        [
            ShelfDocument(
                id: UUID(),
                title: "release plan",
                kind: .markdown,
                created: date(10, 9),
                modified: date(14, 18)
            ),
            ShelfDocument(
                id: UUID(),
                title: "Harbour notes",
                kind: .markdown,
                created: date(12, 9),
                modified: date(15, 10)
            ),
            ShelfDocument(id: UUID(), title: "Login flow", kind: .diagram, created: date(14, 9), modified: date(12, 8)),
            ShelfDocument(id: UUID(), title: "Zebra 2", kind: .text, created: date(1, 9), modified: date(3, 8)),
            ShelfDocument(id: UUID(), title: "Zebra 10", kind: .text, created: date(2, 9), modified: date(2, 8))
        ]
    }

    func titles(_ sort: DocumentSort) -> [[String]] {
        sort.groups(documents, now: now, calendar: calendar).map { $0.elements.map(\.title) }
    }

    @Test func `the latest changed first is the default, by day`() {
        #expect(DocumentSort() == .changed && DocumentSort(rawValue: "changed") == .changed)
        let groups = DocumentSort.changed.groups(documents, now: now, calendar: calendar)
        #expect(groups.map(\.title).prefix(2) == ["Today", "Yesterday"])
        #expect(titles(.changed) == [["Harbour notes"], ["release plan"], ["Login flow"], ["Zebra 2"], ["Zebra 10"]])
    }

    @Test func `the latest made first, by the day it was made`() {
        #expect(titles(.made).flatMap(\.self) == ["Login flow", "Harbour notes", "release plan", "Zebra 10", "Zebra 2"])
    }

    @Test func `by name is one list, as the Finder orders names`() {
        let groups = DocumentSort.name.groups(documents, now: now, calendar: calendar)
        #expect(groups.count == 1 && groups[0].title == nil)
        #expect(titles(.name) == [["Harbour notes", "Login flow", "release plan", "Zebra 2", "Zebra 10"]])
    }

    @Test func `by kind groups them under the kind's name, the latest changed first within`() {
        let groups = DocumentSort.kind.groups(documents, now: now, calendar: calendar)
        #expect(groups.map(\.title) == ["Markdown", "Diagrams", "Text"])
        #expect(titles(.kind) == [["Harbour notes", "release plan"], ["Login flow"], ["Zebra 2", "Zebra 10"]])
    }

    @Test func `a search keeps the documents whose title holds the words, whatever the case and the accents`() {
        let found = ShelfDocument.matching("HARBOUR", in: documents).map(\.title)
        #expect(found == ["Harbour notes"])
        let cafe = ShelfDocument(id: UUID(), title: "Café menu", kind: .text, created: now, modified: now)
        #expect(
            ShelfDocument.matching("cafe me", in: [cafe]).count == 1
                && ShelfDocument.matching("tea", in: [cafe]).isEmpty
        )
        #expect(ShelfDocument.matching("  ", in: documents).count == documents.count)
    }
}
