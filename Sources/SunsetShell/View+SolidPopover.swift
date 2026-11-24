package import SwiftUI

extension View {
    /// A popover's own background, aligned with floating preview cards: the window's surface tinted by
    /// `Design.Fill.popoverShade`, readable over any page and not as dark as an opaque black wash.
    package func solidPopoverBackground() -> some View {
        modifier(PopoverSurfaceModifier())
    }
}
