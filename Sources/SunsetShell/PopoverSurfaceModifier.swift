import SunsetShellModel
import SwiftUI

/// Applies Sunset's middle-ground popover surface, matching color scheme, and notifies any enclosing floating sidebar
/// while the popover is presented so hovering into the popover never collapses the sidebar.
struct PopoverSurfaceModifier: ViewModifier {
    @Environment(\.barTint) private var barTint
    @Environment(\.colorScheme) private var scheme
    @Environment(\.sidebarPopoverHost) private var host

    func body(content: Content) -> some View {
        let captured = host
        content
            .environment(\.colorScheme, barTint.resolved(in: scheme))
            .presentationBackground { PopoverBackdrop() }
            .onAppear {
                if let captured { captured.sidebarPopoverCount += 1 }
            }
            .onDisappear {
                if let captured { captured.sidebarPopoverCount = max(0, captured.sidebarPopoverCount - 1) }
            }
    }
}
