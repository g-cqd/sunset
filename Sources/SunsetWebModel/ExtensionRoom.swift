/// How many extensions' buttons the sidebar's header shows (the owner, 2026-11-20): all when they fit; else as many as fit with
/// the puzzle piece, which lists them all, in the last place.
package enum ExtensionRoom {
    /// `count` buttons in `room` places.
    package static func shown(count: Int, room: Int) -> Int {
        count <= room ? count : max(0, room - 1)
    }

    /// A button can be used when its extension enables it and the tab shown is a web page; in another tab (a terminal, a
    /// document) it is shown, disabled (the owner, 2026-11-21): an action there would run for no page.
    package static func isAvailable(enabled: Bool, inWebTab: Bool) -> Bool {
        enabled && inWebTab
    }

    /// The places `width` holds, each `button` wide, `spacing` apart.
    package static func places(width: Double, button: Double, spacing: Double) -> Int {
        guard width >= button else { return 0 }
        return Int(((width + spacing) / (button + spacing)).rounded(.down))
    }
}
