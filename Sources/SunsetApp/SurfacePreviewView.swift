import AppKit
import IOSurface
import SwiftUI

/// Displays a live thumbnail of an `IOSurface` (a terminal's last rendered frame) in a layer-backed `NSView` with `.resizeAspect` gravity, without copying
/// pixels through the CPU (`n36`).
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
