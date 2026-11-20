import SunsetShell
import SwiftUI

extension View {
    /// A detached window's control in its strip (tasks t132, t133): a capsule `height` tall with the fields' fill and hairline.
    func detachedCapsule(height: Double, surface: SurfaceStyle) -> some View {
        buttonStyle(.plain)
            .frame(height: height)
            .background { Capsule().fill(Color.primary.opacity(Design.Fill.field)) }
            .overlay { Capsule().hairline(surface.layout) }
            .contentShape(Capsule())
            .fixedSize()
    }
}
