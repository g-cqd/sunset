package import Foundation

/// A private page (web step h): what store it uses. Pages with the same group share one store in memory (a private window's, by default);
/// a private tab of a normal window has a group of its own. Nothing of it is written to disk.
package struct PagePrivacy: Sendable, Equatable, Hashable {
    package let group: UUID

    package init(group: UUID = UUID()) { self.group = group }
}
