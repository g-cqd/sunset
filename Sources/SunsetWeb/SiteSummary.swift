package import Foundation

/// Every site that has something of its own (roadmap 0022 W-d): what a site may do, the browser it is shown, blocking
/// paused, a zoom, the Space it opens in; for Settings to list and forget at once.
@MainActor
package enum SiteSummary {
    /// Where each kind is kept.
    @MainActor package struct Stores {
        package let permissions: SitePermissions
        package let agents: SiteAgents
        package let pauses: BlockingPauses
        package let zoom: SiteZoom
        package let spaces: SiteRules<UUID>
        package let hidden: SiteRules<[String]>
        package let kept: KeptSites

        package init(
            permissions: SitePermissions,
            agents: SiteAgents,
            pauses: BlockingPauses,
            zoom: SiteZoom,
            spaces: SiteRules<UUID>,
            hidden: SiteRules<[String]> = HiddenElements.make(),
            kept: KeptSites = KeptSites()
        ) {
            self.kept = kept
            self.permissions = permissions
            self.agents = agents
            self.pauses = pauses
            self.zoom = zoom
            self.spaces = spaces
            self.hidden = hidden
        }

        /// The app's.
        package static var app: Self {
            Self(
                permissions: .shared,
                agents: .shared,
                pauses: ContentBlocker.shared.pauses,
                zoom: .shared,
                spaces: SiteSpaces.shared,
                hidden: HiddenElements.shared,
                kept: .shared
            )
        }
    }

    /// What a site can have of its own.
    package enum Kind: Sendable, Equatable, CaseIterable {
        case permissions, agent, blocking, zoom, hidden, space, kept
    }

    /// A site and what it has, in words, each part of its kind.
    package struct Row: Equatable, Sendable {
        package let host: String
        package let parts: [String]
        package var kinds: [Kind] = []

        package init(host: String, parts: [String], kinds: [Kind] = []) {
            self.host = host
            self.parts = parts
            self.kinds = kinds
        }
    }

    /// Takes one kind of the site's own away; the others stay.
    package static func reset(_ kind: Kind, of host: String, in stores: Stores, profile: UUID? = nil) {
        let pattern = SitePattern(host) ?? .site(host)
        switch kind {
            case .permissions:
                let answers = SitePermissions.sharing(stores.permissions, defaults: [:], profile: profile)
                for permission in SitePermission.allCases { answers.set(nil, permission, for: host) }
            case .agent: stores.agents.set(nil, for: pattern, profile: profile)
            case .blocking: stores.pauses.set(false, for: host, profile: profile)
            case .zoom: stores.zoom.set(1, for: host, remember: stores.zoom.remembers, profile: profile)
            case .hidden: stores.hidden.set(nil, for: pattern, profile: profile)
            case .space: stores.spaces.set(nil, for: pattern, profile: profile)
            case .kept: stores.kept.set(false, for: pattern, profile: profile)
        }
    }

    /// - Parameters:
    ///   - stores: where the rules are.
    ///   - profile: its own rules (roadmap 0050 E); nil: all profiles'.
    ///   - spaceName: a Space's name, by its id; nil for one that is gone.
    /// - Returns: one row a site, by host.
    package static func rows(_ stores: Stores, profile: UUID? = nil, spaceName: (UUID) -> String?) -> [Row] {
        var parts: [String: [(Kind, String)]] = [:]
        for (host, count) in stores.permissions.answeredSites(profile: profile) {
            parts[host, default: []].append((.permissions, count == 1 ? "1 answer" : "\(count) answers"))
        }
        for (host, agent) in stores.agents.rules(profile: profile) {
            parts[host, default: []].append((.agent, "shown \(agent.title)"))
        }
        for host in stores.pauses.paused(profile: profile) {
            parts[host, default: []].append((.blocking, "blocking paused"))
        }
        for (host, level) in stores.zoom.sites(profile: profile) {
            parts[host, default: []].append((.zoom, "zoom \(Int((level * 100).rounded())) %"))
        }
        for (host, selectors) in stores.hidden.rules(profile: profile) {
            let count = selectors.count
            parts[host, default: []].append((.hidden, count == 1 ? "1 element hidden" : "\(count) elements hidden"))
        }
        for (host, space) in stores.spaces.rules(profile: profile) {
            parts[host, default: []].append((.space, "opens in \(spaceName(space) ?? "a Space that is gone")"))
        }
        let kept =
            profile == nil
            ? stores.kept.hosts : stores.kept.hosts(profile: profile).filter { !stores.kept.hosts.contains($0) }
        for host in kept { parts[host, default: []].append((.kept, "data kept")) }
        return parts.sorted { $0.key < $1.key }
            .map { host, list in
                Row(host: host, parts: list.map(\.1), kinds: list.map(\.0))
            }
    }

    /// Takes everything of the site's own away: the defaults apply to it again.
    package static func forget(_ host: String, in stores: Stores, profile: UUID? = nil) {
        for kind in Kind.allCases { reset(kind, of: host, in: stores, profile: profile) }
    }
}
