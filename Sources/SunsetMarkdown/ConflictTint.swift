internal import AppKit
internal import SwiftUI

/// The colours of a merge (roadmap 0023 step M-e): what is here, what the disk says, and what just came from the disk.
enum ConflictTint {
    static let mine = NSColor.systemBlue.withAlphaComponent(0.16)
    static let theirs = NSColor.systemOrange.withAlphaComponent(0.18)
    /// A block the merge just put in: shown for a moment.
    static let merged = NSColor.systemGreen.withAlphaComponent(0.22)

    static var mineColor: Color { Color(nsColor: mine) }
    static var theirsColor: Color { Color(nsColor: theirs) }
    static var mergedColor: Color { Color(nsColor: merged) }
}
