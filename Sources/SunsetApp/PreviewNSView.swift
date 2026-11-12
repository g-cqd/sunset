import AppKit
import IOSurface

/// The layer-backed view behind `SurfacePreviewView`.
final class PreviewNSView: NSView {
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layerContentsRedrawPolicy = .never
        // Each pane's spot has (nearly) the shape it drew in: it fills it, a gap's worth cut at the edges rather than bars beside it (n58).
        layer?.contentsGravity = .resizeAspectFill
        layer?.masksToBounds = true
        layer?.magnificationFilter = .trilinear
        layer?.minificationFilter = .trilinear
    }

    required init?(coder: NSCoder) { nil }

    override var isFlipped: Bool { true }

    func update(surface: IOSurface, background: CGColor) {
        layer?.backgroundColor = background
        layer?.contents = surface
    }
}
