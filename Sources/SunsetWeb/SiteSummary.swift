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

    /// A site and what it has, in words.
    package struct Row: Equatable, Sendable {
        package let host: String
        package let parts: [String]
    }

    /// - Parameters:
    ///   - stores: where the rules are.
    ///   - spaceName: a Space's name, by its id; nil for one that is gone.
    /// - Returns: one row a site, by host.
    package static func rows(_ stores: Stores, spaceName: (UUID) -> String?) -> [Row] {
        var parts: [String: [String]] = [:]
        for (host, count) in stores.permissions.answeredSites {
            parts[host, default: []].append(count == 1 ? "1 answer" : "\(count) answers")
        }
        for (host, agent) in stores.agents.rules { parts[host, default: []].append("shown \(agent.title)") }
        for host in stores.pauses.paused { parts[host, default: []].append("blocking paused") }
        for (host, level) in stores.zoom.sites {
            parts[host, default: []].append("zoom \(Int((level * 100).rounded())) %")
        }
        for (host, selectors) in stores.hidden.rules {
            parts[host, default: []]
                .append(selectors.count == 1 ? "1 element hidden" : "\(selectors.count) elements hidden")
        }
        for (host, space) in stores.spaces.rules {
            parts[host, default: []].append("opens in \(spaceName(space) ?? "a Space that is gone")")
        }
        for host in stores.kept.hosts { parts[host, default: []].append("data kept") }
        return parts.sorted { $0.key < $1.key }.map { Row(host: $0.key, parts: $0.value) }
    }

    /// Takes everything of the site's own away: the defaults apply to it again.
    package static func forget(_ host: String, in stores: Stores) {
        for permission in SitePermission.allCases { stores.permissions.set(nil, permission, for: host) }
        stores.agents.set(nil, for: host)
        stores.pauses.set(false, for: host)
        stores.zoom.set(1, for: host, remember: stores.zoom.remembers)
        stores.spaces.set(nil, for: host)
        stores.hidden.set(nil, for: host)
        stores.kept.set(false, for: host)
    }
}
