package import Foundation
package import SunsetWebModel

/// Which open tabs a page asking to share the screen is offered (`AppShare` chose them in the app target): pages,
/// terminals and documents of every Space, the asking page among them, marked; never a private page, nor a terminal never
/// shown (it has no shell to draw yet).
package enum ShareOffer {
    /// An open tab, as much of it as the choice needs.
    package struct Tab: Sendable {
        package enum Kind: Sendable {
            case page(host: String?, isPrivate: Bool)
            case terminal(started: Bool)
            case document
        }

        package let id: UUID
        package let kind: Kind
        package let title: String
        package let space: String
        package let profile: UUID?

        package init(id: UUID, kind: Kind, title: String, space: String, profile: UUID?) {
            self.id = id
            self.kind = kind
            self.title = title
            self.space = space
            self.profile = profile
        }
    }

    package static func sources(_ tabs: [Tab], asking: UUID?) -> [ShareSource] {
        tabs.compactMap { tab in
            let host: String?
            switch tab.kind {
                case .page(let pageHost, let isPrivate):
                    guard !isPrivate else { return nil }
                    host = pageHost
                case .terminal(let started):
                    guard started else { return nil }
                    host = nil
                case .document: host = nil
            }
            return ShareSource(
                id: tab.id,
                title: tab.title,
                space: tab.space,
                profile: tab.profile,
                host: host,
                isAsking: tab.id == asking
            )
        }
    }
}
