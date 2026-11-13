import SunsetShell
import SwiftUI

/// Glass over a page, or the tab bar's flat capsule.
struct NavigationLook: ViewModifier {
    let flat: Bool
    let atTop: Bool

    func body(content: Content) -> some View {
        if flat {
            content.tabCapsule()
        } else {
            content.barGroup(margin: Design.Space.m, top: atTop)
        }
    }
}
