package import SwiftUI

extension View {
    /// On a scroll view: it bounces only while its content overflows (the owner, 2026-11-17: no bouncing "if there's no
    /// reason to have scrolling"). SwiftUI's own `.basedOnSize` was probed to give AppKit no elasticity even for content that
    /// overflows (`ScrollBounceTests`), so the overflow is measured and the bounce chosen from it.
    package func bouncesOnlyWhenScrolling() -> some View { modifier(BounceWhenScrolling()) }
}
