import Foundation

/// How what brings a pane's content back is written in a file: `{"pane", "kind", "state"}`, in an array (stable text; a dictionary keyed by UUID would
/// encode as a flat list of alternating keys and values).
struct PaneContentRecord: Codable {
    let pane: PaneID
    let kind: String
    let state: [String: String]

    /// The records of `contents` for `panes`, in that order.
    static func records(of contents: [PaneID: PaneDescriptor], in panes: [PaneID]) -> [PaneContentRecord] {
        panes.compactMap { pane in
            contents[pane].map { PaneContentRecord(pane: pane, kind: $0.kind, state: $0.state) }
        }
    }

    /// The first record of each pane.
    static func contents(of records: [PaneContentRecord]) -> [PaneID: PaneDescriptor] {
        var contents: [PaneID: PaneDescriptor] = [:]
        for record in records where contents[record.pane] == nil {
            contents[record.pane] = PaneDescriptor(kind: record.kind, state: record.state)
        }
        return contents
    }
}

/// A file's `contents`, `[{"pane", "kind", "state"}]`, read and written in one place (a Favorite's home, the saved
/// Favorites and a saved Space each did it the same way).
extension KeyedDecodingContainer {
    /// What each pane holds, from the records under `key`; none when there are none.
    func paneContents(forKey key: Key) throws -> [PaneID: PaneDescriptor] {
        PaneContentRecord.contents(of: try decodeIfPresent([PaneContentRecord].self, forKey: key) ?? [])
    }
}

extension KeyedEncodingContainer {
    /// What each of `panes` holds, in their order, as records under `key`.
    mutating func encode(paneContents contents: [PaneID: PaneDescriptor], of panes: [PaneID], forKey key: Key) throws {
        try encode(PaneContentRecord.records(of: contents, in: panes), forKey: key)
    }
}
