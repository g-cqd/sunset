package import SwiftUI

extension View {
    /// The accent `appearance.accent` and `appearance.tint` choose, for this window.
    /// "site": the shown site's colour (`site`), else the system's (roadmap 0047 H).
    package func accent(_ choice: String, tint: [UInt8]?, site: Design.Accent? = nil) -> some View {
        modifier(AccentModifier(accent: choice == "site" ? site ?? .system : Design.Accent.resolve(choice, tint: tint)))
    }
}
