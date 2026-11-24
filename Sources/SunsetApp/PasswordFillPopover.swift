import AppKit
import SwiftUI

/// The one popover filling and saving show (`AppPasswordFill`): transient (gone when clicked away), never the key window,
/// so the page keeps the keyboard; at a rect of the page's view.
@MainActor
final class PasswordFillPopover {
    private var popover: NSPopover?
    /// Whether what is shown is suggestions (closed when their field loses the keyboard) rather than an offer to save.
    private var suggesting = false

    func show(_ content: some View, at rect: CGRect, of view: NSView, edge: NSRectEdge, suggestions: Bool = false) {
        close()
        // AppKit raises for a view with no window (n144): a page that left the screen gets nothing shown.
        guard view.window != nil, !view.isHiddenOrHasHiddenAncestor else { return }
        let popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        // On the window's own background, not the popover's translucent material: as legible in front or not.
        popover.contentViewController = NSHostingController(
            rootView:
                content
                .foregroundStyle(.primary)
                .background(Color(nsColor: .windowBackgroundColor))
        )
        popover.show(relativeTo: rect, of: view, preferredEdge: edge)
        // The page keeps the keyboard: what the person types goes on to the field.
        view.window?.makeFirstResponder(view)
        self.popover = popover
        suggesting = suggestions
    }

    func closeSuggestions() {
        if suggesting { close() }
    }

    func close() {
        popover?.performClose(nil)
        popover = nil
    }
}
