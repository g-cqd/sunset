/// What a page may do with dialogs (white paper §9: an untrusted program's requests have a policy): each one is shown, from the
/// second the panel offers to silence the page, and a silenced page's dialogs are answered without being shown until it is left.
package struct PageDialogPolicy: Equatable, Sendable {
    package init() {}

    package enum Decision: Equatable, Sendable {
        case show(offersSilence: Bool)
        case suppress
    }

    private var asked = 0
    private var silenced = false

    /// Counts a dialog the page asks for, and says what becomes of it.
    package mutating func next() -> Decision {
        if silenced { return .suppress }
        asked += 1
        return .show(offersSilence: asked > 1)
    }

    package mutating func silence() {
        silenced = true
    }

    /// The page was left for another: the next page starts afresh.
    package mutating func pageLeft() {
        self = PageDialogPolicy()
    }
}
