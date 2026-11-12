import AppKit
import SunsetConfig
import SunsetPrivate
import SunsetShell

/// The AppKit view of `SidebarBackdrop`.
final class SidebarBackdropView: NSView {
    var look: SidebarLook? { didSet { if look != oldValue { rebuild() } } }
    private var content: NSView?

    override func layout() {
        super.layout()
        content?.frame = bounds
    }

    private func rebuild() {
        content?.removeFromSuperview()
        content = nil
        guard let look else { return }
        let view: NSView
        switch look.material {
            case .opaque:
                // Raised: the window's colour, a little lighter (`Design.Raised`), resolved for this view's appearance.
                view = NSView()
                view.wantsLayer = true
                var raised = NSColor.windowBackgroundColor.cgColor
                effectiveAppearance.performAsCurrentDrawingAppearance {
                    raised =
                        (NSColor.windowBackgroundColor.blended(withFraction: Design.Raised.lighten, of: .white)
                        ?? .windowBackgroundColor)
                        .cgColor
                }
                view.layer?.backgroundColor = raised
            case .material:
                view = Self.effect(.sidebar)
            case .glass:
                let glass = NSGlassEffectView()
                glass.style = look.glass == .clear ? .clear : .regular
                glass.cornerRadius = 0
                view = glass
            case .fill:
                view = NSView()
        }
        view.frame = bounds
        view.autoresizingMask = [.width, .height]
        addSubview(view)
        if look.material == .material || look.material == .glass, look.blur > 0, let layer = Self.blurLayer(look.blur) {
            // Its own blur radius: a backdrop layer over the material.
            let blur = NSView(frame: bounds)
            blur.autoresizingMask = [.width, .height]
            blur.wantsLayer = true
            layer.frame = blur.bounds
            layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
            blur.layer?.addSublayer(layer)
            view.addSubview(blur)
        }
        if let tint = look.tint, tint.count == 3, look.tintAlpha > 0 {
            let overlay = NSView(frame: bounds)
            overlay.autoresizingMask = [.width, .height]
            overlay.wantsLayer = true
            overlay.layer?.backgroundColor =
                NSColor(
                    srgbRed: Double(tint[0]) / 255,
                    green: Double(tint[1]) / 255,
                    blue: Double(tint[2]) / 255,
                    alpha: look.tintAlpha
                )
                .cgColor
            addSubview(overlay)
        }
        content = view
    }

    private static func effect(_ material: NSVisualEffectView.Material) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    @MainActor private static func blurLayer(_ radius: Double) -> CALayer? { BackdropBlur.makeLayer(radius: radius) }
}
