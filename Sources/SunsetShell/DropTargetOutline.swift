package import SwiftUI

/// A place a drag could be dropped, outlined while the drag is under way (the owner, 2026-11-17: "the target area show
/// so that we know where to drop tabs"): a dashed line in the accent's colour, and under the pointer a fill and a full
/// line. Drawn inside the place's bounds: nothing moves.
package struct DropTargetOutline: ViewModifier {
    let shown: Bool
    let targeted: Bool
    let radius: Double
    @Environment(\.accent) private var accent

    package func body(content: Content) -> some View {
        content.overlay {
            if shown {
                let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
                ZStack {
                    shape.fill(accent.color.opacity(targeted ? Design.Fill.target : Design.Fill.faint))
                    shape.strokeBorder(
                        accent.color.opacity(targeted ? 1 : Design.Line.dropOutline),
                        style: StrokeStyle(lineWidth: 1, dash: targeted ? [] : Design.Line.dropDash)
                    )
                }
                .allowsHitTesting(false)
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
