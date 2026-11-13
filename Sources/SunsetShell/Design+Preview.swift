package import SwiftUI

extension Design {
    /// The tab preview card (`TabPreviewHost`).
    package enum Preview {
        /// From a row to the next, and in and out.
        package static let glide = Animation.spring(
            duration: Double(ProcessInfo.processInfo.environment["SUNSET_GLIDE"] ?? "") ?? 0.3,
            bounce: 0.12
        )
        /// How long it stays after the pointer left a row: long enough to reach the next one.
        package static let linger = Duration.milliseconds(140)
        /// It grows in from this scale, out of its tab's row.
        package static let inScale = 0.5
        /// The card's height around its miniature: the label and the spacing.
        package static let chrome = 44.0
        /// The content of a tab gives way to the next one's.
        package static let swap = Animation.easeOut(
            duration: Double(ProcessInfo.processInfo.environment["SUNSET_GLIDE"] ?? "") ?? 0.18
        )
    }
}
