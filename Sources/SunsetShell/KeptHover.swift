import SwiftUI

/// `View.keptHover(_:)`.
struct KeptHover: ViewModifier {
    @Binding var hovering: Bool
    @State private var keeper = HoverKeeper()
    private let menus = MenuTracking.shared

    func body(content: Content) -> some View {
        content
            .onHover { inside in
                keeper.hover(inside, menuOpen: menus.isOpen)
                hovering = keeper.hovering
            }
            .onChange(of: menus.isOpen) { _, open in
                guard !open else { return }
                keeper.menuClosed()
                hovering = keeper.hovering
            }
    }
}
