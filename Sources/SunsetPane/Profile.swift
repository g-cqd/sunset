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
    /// What WebKit keeps between runs in this profile (ADR-0081), where it differs from the app's `web.keep`.
    public var keep = Keep()

    /// Each choice by its name in the configuration (`web.keep`'s values); nil: the app's.
    public struct Keep: Sendable, Equatable, Codable {
        public var cache: String?
        public var traces: String?
        public var siteData: String?

        public init(cache: String? = nil, traces: String? = nil, siteData: String? = nil) {
            self.cache = cache
            self.traces = traces
            self.siteData = siteData
        }
    }

    public init(id: ID = ID(), name: String, icon: PaneIcon? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
    }

    private enum CodingKeys: String, CodingKey { case id, name, icon, keep }

    /// A session of before profiles kept anything of their own has no `keep`: the app's then.
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(ID.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        icon = try values.decodeIfPresent(PaneIcon.self, forKey: .icon)
        keep = try values.decodeIfPresent(Keep.self, forKey: .keep) ?? Keep()
    }

    /// The first profile as it is before anyone names it.
    public static var first: Profile { Profile(id: firstID, name: "Personal") }
    public var isFirst: Bool { id == Self.firstID }
}
