public import Foundation

/// A Space: a named set of Favorites and Tabs that a window shows. This is what names it; what it holds is beside it
/// (`SavedSpace` in the file, the Space's model while the app runs). Spaces are the app's, in one order for every window
/// (2026-11-16).
public struct Space: Sendable, Equatable, Identifiable, Codable {
    public typealias ID = UUID

    /// Never changes: a Space is renamed without anything that names it changing.
    public let id: ID
    /// Empty for the Space of before there were Spaces: unnamed, and not shown as one until a second exists.
    public var name: String
    public var icon: PaneIcon?
    /// The profile it belongs to; nil is the one profile there is until profiles exist (P-a).
    public var profile: UUID?
    /// Room for a look of its own (tint, colour scheme, material; R4: anticipated, no editor yet): carried as it was
    /// written, so that a build that does not read it does not strip what another wrote.
    public var look: [String: String]?

    public init(id: ID = ID(), name: String = "", icon: PaneIcon? = nil, profile: UUID? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
        self.profile = profile
    }
}
