import AppKit
import IOSurface
import SwiftUI

/// Shows an `IOSurface` small, in a layer-backed `NSView` with `.resizeAspect` gravity, without copying pixels through the CPU (`n36`). The surface is the
/// last frame a terminal drew: a hidden tab draws nothing, so what it printed since is not in it.
struct SurfacePreviewView: NSViewRepresentable {
    let surface: IOSurface
    let background: CGColor

    func makeNSView(context: Context) -> PreviewNSView {
        let view = PreviewNSView()
        view.update(surface: surface, background: background)
        return view
    }

    func updateNSView(_ view: PreviewNSView, context: Context) {
        view.update(surface: surface, background: background)
    }
}
