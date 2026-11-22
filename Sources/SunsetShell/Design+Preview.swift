package import SwiftUI

extension Design {
    /// The tab preview card (`TabPreviewHost`).
    package enum Preview {
        /// From a row to the next, and in and out: quick, without a bounce (0.3 s was too slow).
        package static let glide = Animation.spring(duration: 0.16, bounce: 0)
        /// How long it stays after the pointer left a row: long enough to reach the next one.
        package static let linger = Duration.milliseconds(140)
        /// It grows in from this scale, out of its tab's row: near its size, so that the short animation is not a jump.
        package static let inScale = 0.8
        /// The card's height around its miniature: the label and the spacing.
        package static let chrome = 44.0
        /// The content of a tab gives way to the next one's.
        package static let swap = Animation.easeOut(duration: 0.1)
    }
}
