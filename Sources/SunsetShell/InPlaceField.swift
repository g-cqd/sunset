import SunsetMetrics
import SwiftUI

/// The look of `View.inPlaceField()`.
struct InPlaceField: ViewModifier {
    @Environment(\.surfaceStyle) private var surface

    func body(content: Content) -> some View {
        content
            .fieldSurface(height: surface.layout.closeButtonSize)
            .padding(.leading, Design.Space.xs - Design.Space.m)
    }
}
