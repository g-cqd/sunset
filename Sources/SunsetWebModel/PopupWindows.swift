/// Which pop-ups open in a pop-up window, as `web.popupWindows` says.
package enum PopupWindows: String, Sendable, Equatable {
    /// Those the page gave a size (`window.open` with a width): sign-in, payment and share dialogs.
    case sized
    /// Every one a script opens, sized or not.
    case scripted
    /// None: they are tabs.
    case never

    /// Whether a page asked for goes to a pop-up window: never one a link with a target asked for ("we should respect
    /// target blank though, those should be tabs").
    package func takes(sized: Bool, fromLink: Bool) -> Bool {
        guard !fromLink else { return false }
        switch self {
            case .sized: return sized
            case .scripted: return true
            case .never: return false
        }
    }
}
