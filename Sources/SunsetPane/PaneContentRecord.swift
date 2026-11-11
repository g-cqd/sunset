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
