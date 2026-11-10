import AppKit
import IOSurface

/// The layer-backed view behind `SurfacePreviewView`.
final class PreviewNSView: NSView {
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layerContentsRedrawPolicy = .never
        layer?.contentsGravity = .resizeAspect
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
