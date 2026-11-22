package import Foundation

/// A tab that can be shared into a call: what the list shows of it, its profile, and what draws its frames.
package struct ShareSource: Identifiable, Sendable {
    package let id: UUID
    package let title: String
    package let space: String
    /// Its profile; nil: the first.
    package let profile: UUID?
    /// A page's host, when it is a page: sharing stops if it goes to another site.
    package let host: String?
    /// The tab that asks: offered too, in its Space, marked.
    package let isAsking: Bool

    /// What the list says of it: its title, "(this tab)" after the asking tab's.
    package var label: String {
        isAsking ? title + " (this tab)" : title
    }

    package init(id: UUID, title: String, space: String, profile: UUID?, host: String?, isAsking: Bool = false) {
        self.id = id
        self.title = title
        self.space = space
        self.profile = profile
        self.host = host
        self.isAsking = isAsking
    }
}
