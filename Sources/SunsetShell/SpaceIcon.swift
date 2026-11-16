import SunsetPane
import SwiftUI

/// A Space's picture: its icon, or the first letter of its name.
struct SpaceIcon: View {
    let space: Space

    var body: some View {
        if let icon = space.icon, PaneIconView.canShow(icon) {
            PaneIconView(icon: icon)
        } else {
            Text(space.name.prefix(1).uppercased())
                .font(.system(size: Design.Symbol.row, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}
