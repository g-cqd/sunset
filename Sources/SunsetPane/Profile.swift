public import Foundation

/// A profile (R4): a web identity. Its pages have their own website data (cookies, logins, storage), and the Pinned grid
/// is its own. A Space has one profile; several Spaces may share it. There is always the first profile, which a Space
/// that names none belongs to: what Sunset kept before there were profiles is its.
public struct Profile: Sendable, Equatable, Identifiable, Codable {
    public typealias ID = UUID

    /// The first profile's: always the same, so that a Space of before profiles, which names none, is of it.
    public static let firstID = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1))

    public let id: ID
    public var name: String
    public var icon: PaneIcon?

    public init(id: ID = ID(), name: String, icon: PaneIcon? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
    }

    /// The first profile as it is before anyone names it.
    public static var first: Profile { Profile(id: firstID, name: "Personal") }
    public var isFirst: Bool { id == Self.firstID }
}
