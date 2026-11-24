import SwiftUI

/// Applies Sunset's middle-ground popover surface and matching color scheme.
struct PopoverSurfaceModifier: ViewModifier {
    @Environment(\.barTint) private var barTint
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content
            .environment(\.colorScheme, barTint.resolved(in: scheme))
            .presentationBackground { PopoverBackdrop() }
    }
}
