public import Foundation

/// One window as it was left: its tabs, and what brings the content of each pane back (`PaneDescriptor`). A pane with nothing saved is a new terminal.
public struct SavedWindow: Sendable, Equatable, Codable {
    public var workspace: Workspace
    public var contents: [PaneID: PaneDescriptor]

    public init(workspace: Workspace, contents: [PaneID: PaneDescriptor] = [:]) {
        self.workspace = workspace
        // Only the panes the window has: what is compared and what is written are then the same thing.
        let panes = Set(workspace.allPanes)
        self.contents = contents.filter { panes.contains($0.key) }
    }

    /// `contents` is `[{"pane", "kind", "state"}]`. A file from before there were kinds has `directories`, `[{"pane", "directory"}]`: terminals.
    private enum Key: String, CodingKey { case workspace, contents, directories }
    private struct Entry: Codable {
        let pane: PaneID
        let kind: String
        let state: [String: String]
    }
    private struct OldEntry: Codable {
        let pane: PaneID
        let directory: String
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        let workspace = try container.decode(Workspace.self, forKey: .workspace)
        var contents: [PaneID: PaneDescriptor] = [:]
        if let entries = try container.decodeIfPresent([Entry].self, forKey: .contents) {
            for entry in entries where contents[entry.pane] == nil {
                contents[entry.pane] = PaneDescriptor(kind: entry.kind, state: entry.state)
            }
        } else if let entries = try container.decodeIfPresent([OldEntry].self, forKey: .directories) {
            for entry in entries where contents[entry.pane] == nil {
                contents[entry.pane] = .terminal(directory: entry.directory)
            }
        }
        self.init(workspace: workspace, contents: contents)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        try container.encode(workspace, forKey: .workspace)
        // An array in pane order: stable text, and a UUID-keyed dictionary would encode as a flat list of alternating keys and values.
        let entries = workspace.allPanes.compactMap { pane in
            contents[pane].map { Entry(pane: pane, kind: $0.kind, state: $0.state) }
        }
        try container.encode(entries, forKey: .contents)
    }
}
