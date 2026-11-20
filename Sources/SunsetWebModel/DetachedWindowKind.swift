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
}
