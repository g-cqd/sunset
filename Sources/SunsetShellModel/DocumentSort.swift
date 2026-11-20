package import Foundation
import SunsetRuntime

/// The order of the documents in a sidebar list (the owner, 2026-11-15): the latest changed first unless chosen otherwise.
package enum DocumentSort: String, Sendable, CaseIterable {
    case changed, made, name, kind

    package init() {
        self = .changed
    }

    /// As the sort menu names it.
    package var title: String {
        switch self {
            case .changed: "Last changed"
            case .made: "Last created"
            case .name: "Name"
            case .kind: "Kind"
        }
    }

    /// The documents in this order, under their headings: by day for the two orders by date, by kind, or one list by name.
    /// - Complexity: O(n log n).
    package func groups(_ documents: [ShelfDocument], now: Date = Runtime.live.now(), calendar: Calendar = .current)
        -> [ListGroup<ShelfDocument>]
    {
        switch self {
            case .changed:
                let sorted = documents.sorted { $0.modified > $1.modified }
                return ListGroup.days(sorted, by: \.modified, now: now, calendar: calendar)
            case .made:
                let sorted = documents.sorted { $0.created > $1.created }
                return ListGroup.days(sorted, by: \.created, now: now, calendar: calendar)
            case .name:
                let sorted = documents.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
                return sorted.isEmpty ? [] : [ListGroup(title: nil, elements: sorted)]
            case .kind:
                return ShelfDocument.Kind.allCases.compactMap { kind in
                    let of = documents.filter { $0.kind == kind }.sorted { $0.modified > $1.modified }
                    return of.isEmpty ? nil : ListGroup(title: kind.title, elements: of)
                }
        }
    }
}
