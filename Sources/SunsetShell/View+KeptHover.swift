package import SwiftUI

extension View {
    /// `onHover` into `hovering`, but its end held while a menu is open (`HoverKeeper`; the crash of note n46): a view that
    /// shows a menu's button on hover keeps it while the menu is up.
    package func keptHover(_ hovering: Binding<Bool>) -> some View {
        modifier(KeptHover(hovering: hovering))
    }
}
