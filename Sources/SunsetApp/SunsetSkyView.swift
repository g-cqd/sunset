import SwiftUI

/// Sunset's sky, alive (0084 G), with its sun in the display's extended range: `SunsetSkyLayerView`.
struct SunsetSkyView: NSViewRepresentable {
    /// What it draws, from the seconds since it appeared and its size in points.
    let frameAt: (Double, CGSize) -> SunsetSkyFrame

    func makeNSView(context: Context) -> SunsetSkyLayerView {
        SunsetSkyLayerView(frameAt: frameAt)
    }

    func updateNSView(_ view: SunsetSkyLayerView, context: Context) {
        view.frameAt = frameAt
    }
}
