/// Where a page opened from another goes (R1's link menu, and a link asking for a new tab).
package enum WebPlacement: Sendable, Equatable {
    /// A tab right after the opener's, not shown (the owner's answer for a link's new tab).
    case tabAfter
    case splitRight
    case splitDown
    /// A window of its own (R1: only on a click; a page asking for a sized window gets one too).
    case window
    /// A private tab right after, with a store of its own (web step h).
    case privateTab
    /// What the page asked for itself (a link with a target, a pop-up after a click, WebKit's Open Image or Video in New
    /// Window): a tab right after the opener's, shown as `web.showOpenedPages` says (notes n64, n65).
    case opened
    /// A pop-up window (task t132): the page alone in a window with no sidebar, in no Space's tabs until moved to one.
    case popup
}
