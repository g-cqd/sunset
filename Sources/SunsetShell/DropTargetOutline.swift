package import SwiftUI

/// The place a drag would land, under the pointer only (the owner, 2026-11-21, note n79: fewer targets, white, blended in
/// the chrome; it replaced outlining every place that could take the drag): a white veil and edge, blended with what is
/// under them. Drawn inside the place's bounds.
package struct DropTargetOutline: ViewModifier {
    let shown: Bool
    let targeted: Bool
    let radius: Double

    package func body(content: Content) -> some View {
        content.overlay {
            if shown, targeted {
                DropVeil(shape: RoundedRectangle(cornerRadius: radius, style: .continuous))
                    .transition(.opacity)
            }
        }
    }
}

extension View {
    /// Outlines this place while a drag that it would take is under way.
    package func dropTarget(shown: Bool, targeted: Bool, radius: Double) -> some View {
        modifier(DropTargetOutline(shown: shown, targeted: targeted, radius: radius))
    }
}
