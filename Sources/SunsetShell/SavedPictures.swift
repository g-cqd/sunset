package import SunsetPane

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
