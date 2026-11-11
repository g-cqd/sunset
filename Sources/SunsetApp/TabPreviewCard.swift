import IOSurface
import SunsetConfig
import SunsetShell
import SunsetShellBridge
import SwiftUI

/// A floating card next to the sidebar that previews an unselected tab's current terminal screen when the pointer hovers over its row (`n36`).
struct TabPreviewCard: View {
    let model: TerminalModel
    let surface: IOSurface
    let layout: Configuration.Layout

    private static let width = 280.0

    private var height: Double {
        guard surface.width > 0, surface.height > 0 else { return 175 }
        let ratio = Double(surface.height) / Double(surface.width)
        return min(max(Self.width * ratio, 110), 220)
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        VStack(alignment: .leading, spacing: 6) {
            TabLabel(
                model: model,
                showIcon: true,
                showTitle: true,
                showDirectory: true,
                showProgress: false
            )
            .padding(.horizontal, 10)
            .padding(.top, 8)
            SurfacePreviewView(surface: surface, background: model.layerBackground)
                .frame(width: Self.width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .padding(.horizontal, 6)
                .padding(.bottom, 6)
        }
        .frame(width: Self.width + 12)
        .background(.ultraThinMaterial, in: shape)
        .overlay { shape.hairline(ShellSettings.Layout(layout)) }
        .shadow(color: .black.opacity(0.28), radius: 12, y: 4)
        .allowsHitTesting(false)
    }
}
