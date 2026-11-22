package import Foundation

/// Another profile than its Space's, a page was reloaded as: its id, nil for the first.
package struct OtherProfile: Equatable, Sendable {
    package let id: UUID?

    package init(
        id: UUID?
    ) {
        self.id = id
    }
}
