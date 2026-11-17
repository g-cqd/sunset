package import SunsetPane
package import SwiftUI

extension EnvironmentValues {
    /// The second line of a tab (its directory, a page's address) in the monospaced face: `tabs.bar.monospacedDirectory`, on by default.
    @Entry package var monospacedDetail = true
    /// The picture of a tab that is not running, when the app has one for what it would start from (a page: its site's
    /// icon, kept; roadmap 0035 H); nil: the kind's mark.
    @Entry package var savedPicture = SavedPictures()
}

/// Where the pictures of tabs not running come from (`EnvironmentValues.savedPicture`): the same when `source` is.
package struct SavedPictures: Equatable {
    /// What the pictures depend on, beside what the lookup reads (it is observed).
    let source: Int
    let find: @MainActor (PaneDescriptor) -> PaneGlyph?

    package init(source: Int = 0, find: @escaping @MainActor (PaneDescriptor) -> PaneGlyph? = { _ in nil }) {
        self.source = source
        self.find = find
    }

    @MainActor package func callAsFunction(_ saved: PaneDescriptor) -> PaneGlyph? { find(saved) }

    package static func == (one: Self, other: Self) -> Bool { one.source == other.source }
}
