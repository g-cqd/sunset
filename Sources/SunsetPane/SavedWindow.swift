public import Foundation

/// One window as it was left: its tabs and the directory each pane was in (programs cannot be saved; a restored pane starts a new shell there).
public struct SavedWindow: Sendable, Equatable, Codable {
    public var workspace: Workspace
    public var directories: [PaneID: String]

    public init(workspace: Workspace, directories: [PaneID: String] = [:]) {
        self.workspace = workspace
        self.directories = directories
    }

    private enum Key: String, CodingKey { case workspace, directories }
    private struct Entry: Codable {
        let pane: PaneID
        let directory: String
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        workspace = try container.decode(Workspace.self, forKey: .workspace)
        let entries = try container.decodeIfPresent([Entry].self, forKey: .directories) ?? []
        directories = Dictionary(entries.map { ($0.pane, $0.directory) }, uniquingKeysWith: { first, _ in first })
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        try container.encode(workspace, forKey: .workspace)
        // An array in pane order: stable text, and a UUID-keyed dictionary would encode as a flat list of alternating keys and values.
        let entries = workspace.allPanes.compactMap { pane in directories[pane].map { Entry(pane: pane, directory: $0) }
        }
        try container.encode(entries, forKey: .directories)
    }
}
