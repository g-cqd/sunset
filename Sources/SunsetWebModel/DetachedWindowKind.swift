/// A page in a window of its own, in no Space's tabs until moved to one: a page's pop-up (task t132), or a peek at a link
/// from another app (the owner's note n66).
package enum DetachedWindowKind: Sendable, Equatable {
    case popup
    case peek

    /// Back, forward and an address field: the peek's only ("this should only be possible for the peek windows, not the popup
    /// ones").
    package var navigates: Bool {
        self == .peek
    }

    /// A window a detached page may move to, as much of it as the choice needs.
    package struct Window: Sendable {
        package let isPrivate: Bool

        package init(isPrivate: Bool) {
            self.isPrivate = isPrivate
        }
    }

    /// The Spaces' menu, for a page that is not private: a private page's tab is in no Space (seen 2026-11-20: it offered
    /// them all, and a private page went to a Space).
    package static func offersSpaces(private: Bool) -> Bool {
        !`private`
    }

    /// A private page goes to a private window only, and a normal page to a normal one.
    package static func fits(window: Window, private: Bool) -> Bool {
        window.isPrivate == `private`
    }
}
