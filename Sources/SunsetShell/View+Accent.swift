package import SwiftUI

extension View {
    /// The accent `appearance.accent` and `appearance.tint` choose, for this window.
    package func accent(_ choice: String, tint: [UInt8]?) -> some View {
        modifier(AccentModifier(accent: Design.Accent.resolve(choice, tint: tint)))
    }
}
