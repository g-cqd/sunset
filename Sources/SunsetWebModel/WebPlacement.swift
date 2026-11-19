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
}
