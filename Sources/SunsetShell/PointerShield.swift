package import AppKit

/// Windows whose content is covered by a modal surface (the command bar's backdrop, t232): the views beneath ignore the pointer
/// there. AppKit sends tracking-area events (hover, the pointer's shape) to a view whatever covers it, so the covered views ask.
@MainActor
package enum PointerShield {
    private static var shielded: Set<ObjectIdentifier> = []

    package static func isShielded(_ window: NSWindow?) -> Bool {
        window.map { shielded.contains(ObjectIdentifier($0)) } ?? false
    }

    static func set(_ on: Bool, for window: NSWindow) {
        let id = ObjectIdentifier(window)
        guard shielded.contains(id) != on else { return }
        if on { shielded.insert(id) } else { shielded.remove(id) }
        // The covered views' pointer shapes go (or come back).
        window.resetCursorRects()
    }
}
