package import Foundation
package import SunsetStorage

/// The sites whose data is kept when Sunset quits while `web.keep.siteData` keeps the chosen ones (ADR-0081): chosen from a
/// site's panel, or by themselves when a password is sent from one of their pages. Kept as sealed records of the state
/// database, or in memory until the app quits.
@MainActor
package final class KeptSites {
    package static let shared = KeptSites()

    private let store: SiteRules<Bool>
    /// The mark that the list was filled once with the sites holding cookies then (ADR-0081, 3), kept with the list: a test
    /// copy shares WebKit's stores and the defaults with the person's Sunset, never its sealed store.
    package var marks: SealedTable? {
        didSet { seeded = marks.map { !$0.all().rows.isEmpty } ?? false }
    }
    private var seeded = false
    private static let seededMark = "seeded"

    package init(table: SealedTable? = nil, marks: SealedTable? = nil) {
        store = SiteRules(table: table, allowsBareLabel: true, encode: { _ in "1" }, decode: { _ in true })
        self.marks = marks
        seeded = marks.map { !$0.all().rows.isEmpty } ?? false
    }

    /// Whether the profile `id` (nil: the first) keeps the chosen sites only: the site's panel then offers to keep it.
    package var applies: (UUID?) -> Bool = { _ in false }

    package var table: SealedTable? {
        get { store.table }
        set { store.table = newValue }
    }

    /// The sites kept, by host.
    package var hosts: [String] { store.rules.map(\.host) }

    /// Whether `host`'s data is kept: it, or a site it is under, is on the list.
    package func keeps(_ host: String?) -> Bool { store.value(for: host) == true }

    /// Puts `host` on the list, or takes it off.
    package func set(_ kept: Bool, for host: String?) { store.set(kept ? true : nil, for: host) }

    /// The first time only: every site of `records` (WebKit's, holding cookies now) is put on the list.
    /// - Returns: whether it filled the list now.
    @discardableResult
    package func seedOnce(with records: [String]) -> Bool {
        guard !seeded else { return false }
        for record in records { set(true, for: record) }
        seeded = true
        marks?.put(Self.seededMark, payload: Data("1".utf8))
        return true
    }
}
