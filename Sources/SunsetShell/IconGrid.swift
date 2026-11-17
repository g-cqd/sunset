import AppKit
import SwiftUI

/// The icon picker's grid in SwiftUI: `IconGridView` in its scroll view. The icons are handed over when `generation`
/// changes, not at each update (the name under the pointer changes the picker's state, and that must cost nothing here).
struct IconGrid: NSViewRepresentable {
    let items: [IconChoice]
    let generation: Int
    let chosen: String?
    let accent: Color
    let pick: (IconChoice) -> Void
    let hover: (IconChoice?) -> Void

    final class Coordinator {
        var generation: Int?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> IconGridScrollView { IconGridScrollView(frame: .zero) }

    func updateNSView(_ scroll: IconGridScrollView, context: Context) {
        let grid = scroll.grid
        grid.onPick = pick
        grid.onHover = hover
        grid.accent = NSColor(accent)
        grid.chosen = chosen
        guard context.coordinator.generation != generation else { return }
        context.coordinator.generation = generation
        grid.show(items)
    }
}
