import Foundation
package import SunsetPane

/// What a Space's editor holds while it is open (the owner, 2026-11-17: three fields, Save and Cancel): nothing of it is
/// the Space's until it is saved, and a new Space is not made before.
package struct SpaceDraft: Equatable, Identifiable {
    /// The Space edited; nil for one that is not made yet.
    package let space: Space.ID?
    package var name: String
    /// The colour that tints the window showing the Space.
    package var tint: IconColor?
    package var icon: PaneIcon?

    package var id: String { space?.uuidString ?? "new" }
    /// A Space has a name.
    package var canSave: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    package init(space: Space.ID?, name: String, tint: IconColor? = nil, icon: PaneIcon? = nil) {
        self.space = space
        self.name = name
        self.tint = tint
        self.icon = icon
    }
}
