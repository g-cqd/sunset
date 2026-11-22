import Foundation
import SunsetDocuments
import SunsetRuntime
package import SunsetStorage
package import SunsetWebModel

/// Sunset WebKit's store of before, merged once into the shared one: its documents (under their own ids) and its history
/// (a page in both keeps the visits of both) are added; its session and settings give way to Sunset's. Its folder is
/// left as it was, a backup: a copy of it is opened, in `scratch`, and removed after. Done once: a mark in the shared
/// store says so.
@MainActor
package enum FormerStoreMerge {
    package struct Merged: Equatable {
        package var documents = 0
        package var pages = 0
    }

    /// The mark's table.
    private static let mark = "merged-stores"

    /// Merges `former` into `current` when it was not yet and there is something; what was added, or nil.
    @discardableResult
    package static func run(
        into current: SunsetStore,
        history: HistoryStore?,
        from former: StoragePlaces,
        scratch: String
    ) -> Merged? {
        guard let marks = current.table(mark), marks.count() == 0,
            FileManager.default.fileExists(atPath: former.state)
        else { return nil }
        let copy = scratch + "/former-\(UUID().uuidString)"
        defer { try? FileManager.default.removeItem(atPath: copy) }
        guard (try? FileManager.default.createDirectory(atPath: scratch, withIntermediateDirectories: true)) != nil,
            (try? FileManager.default.copyItem(atPath: former.directory, toPath: copy)) != nil
        else { return nil }
        let old = SunsetStore(places: former.moved(to: copy), problems: StorageProblems()) { false }
        defer { old.close() }
        // Without its key nothing of it opens: left for another time.
        guard old.key != nil else { return nil }
        var merged = Merged()
        if let from = old.documents, let into = current.documents {
            for document in from.documents {
                guard let text = try? from.text(of: document.id), (try? into.adopt(document, text: text)) == true
                else { continue }
                merged.documents += 1
            }
        }
        let pages = HistoryStore(table: old.table("history"), atOnceBelow: .max).entries(limit: .max)
        history?.merge(pages)
        merged.pages = pages.count
        marks.put(
            former.directory,
            payload: Data(former.directory.utf8),
            sort: Runtime.live.now().timeIntervalSince1970
        )
        return merged
    }
}
