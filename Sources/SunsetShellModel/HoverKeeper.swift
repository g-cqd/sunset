/// A hover that does not end while a menu is open (the owner's crash of 2026-11-18, note n46: a button shown on hover left
/// while its menu was up, and AppKit laid the window out against it). An end of hover while a menu tracks is held until the
/// menu closes.
package struct HoverKeeper: Equatable, Sendable {
    package private(set) var hovering = false
    private var held: Bool?

    package init() {}

    /// The pointer came in or left; `menuOpen`: a menu tracks now.
    package mutating func hover(_ inside: Bool, menuOpen: Bool) {
        if !inside, menuOpen, hovering {
            held = false
            return
        }
        held = nil
        hovering = inside
    }

    /// The menu closed: a hover's end held is applied.
    package mutating func menuClosed() {
        if let held { hovering = held }
        held = nil
    }
}
