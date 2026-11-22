/// Where a page opened from another goes (Sunset's link menu, and a link asking for a new tab).
package enum WebPlacement: Sendable, Equatable {
    /// A tab right after the opener's, not shown: where a link's new tab goes.
    case tabAfter
    case splitRight
    case splitDown
    /// A window of its own (only on a click; a page asking for a sized window gets one too).
    case window
    /// A private tab right after, with a store of its own.
    case privateTab
    /// What the page asked for itself (a link with a target, a pop-up after a click, WebKit's Open Image or Video in New
    /// Window): a tab right after the opener's, shown as `web.showOpenedPages` says.
    case opened
    /// A pop-up window: the page alone in a window with no sidebar, in no Space's tabs until moved to one.
    case popup
}
