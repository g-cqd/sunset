import SwiftUI

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
