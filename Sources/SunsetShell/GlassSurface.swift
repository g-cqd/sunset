import SwiftUI

/// Applies Liquid Glass when the window surface style is `.glass`; no-op otherwise.
struct GlassSurface<S: InsettableShape>: ViewModifier {
    let enabled: Bool
    let clear: Bool
    let shape: S

    func body(content: Content) -> some View {
        if enabled {
            content.glassEffect(clear ? .clear : .regular, in: shape)
        } else {
            content
        }
    }
}
