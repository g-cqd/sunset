package import SwiftUI

extension View {
    /// A capsule of the tab bar's row (`Design.TabCapsules`): the field's fill and hairline, the row's height; its controls are
    /// capsules of that height too.
    package func tabCapsule() -> some View {
        modifier(TabCapsuleLook())
    }
}
