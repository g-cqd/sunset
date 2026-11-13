package import SwiftUI

/// How a bar's groups come and go: sliding in from beyond the edge they sit at, not fading (owner, 2026-11-13).
package enum BarGroupSlide {
    /// Moved by the group's height and its inset from the edge, so that it starts wholly past the edge.
    package static func transition(atTop: Bool, inset: Double) -> AnyTransition {
        let distance = Design.Size.bar + inset
        return .offset(y: atTop ? -distance : distance)
    }

    package static let animation = Animation.easeOut(duration: 0.18)
}
