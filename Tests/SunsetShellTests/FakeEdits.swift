@testable import SunsetShell
@testable import SunsetShellModel

/// A document as the tab model sees it: whether it has edits, how many panes show it, and what was asked of it.
@MainActor final class FakeEdits {
    let title: String
    var isEdited = true
    var paneCount = 1
    var saves = true
    private(set) var saved = 0
    private(set) var discarded = 0

    init(_ title: String) {
        self.title = title
    }

    var unsaved: UnsavedEdits? {
        guard isEdited else { return nil }
        return UnsavedEdits(
            id: ObjectIdentifier(self),
            title: title,
            paneCount: paneCount,
            save: { [self] in
                saved += 1
                if saves { isEdited = false }
                return saves
            },
            discard: { [self] in discarded += 1 }
        )
    }
}
