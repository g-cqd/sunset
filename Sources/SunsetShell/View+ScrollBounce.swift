package import SwiftUI

extension View {
    /// On a scroll view: it bounces only while its content overflows (the owner, 2026-11-17: no bouncing "if there's no
    /// reason to have scrolling"). SwiftUI's own `.basedOnSize` was probed to give AppKit no elasticity even for content that
    /// overflows (`ScrollBounceTests`), so the overflow is measured and the bounce chosen from it.
    package func bouncesOnlyWhenScrolling() -> some View { modifier(BounceWhenScrolling()) }
}

/// What `View.bouncesOnlyWhenScrolling()` does.
struct BounceWhenScrolling: ViewModifier {
    @State private var overflows = false

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(
                for: Bool.self,
                of: { geometry in
                    geometry.contentSize.height > geometry.containerSize.height + 0.5
                        || geometry.contentSize.width > geometry.containerSize.width + 0.5
                }
            ) { _, new in overflows = new }
            .scrollBounceBehavior(overflows ? .always : .basedOnSize, axes: [.vertical, .horizontal])
    }
}
