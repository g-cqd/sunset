import AppKit
import SunsetConfig
import SunsetPrivate

/// What sits behind the terminal of a window: nothing (an opaque window), a system material, Liquid Glass, or nothing at all with the desktop blurred through
/// the window. It is a view under the window's content, in the frame view that holds the content; the terminal draws its default background translucent
/// over it.
///
/// Public APIs, as documented by Apple: `NSVisualEffectView` with `.behindWindow` blending blurs what is behind the window; `NSGlassEffectView` (macOS 26)
/// has a `style` (`.regular`, `.clear`) and a `tintColor`; a window shows what is behind it only when it is not opaque and its background colour is clear
/// (`NSWindow.isOpaque`, `backgroundColor`). The blur radius of a transparent window is the private window-server call in `SunsetPrivate`.
@MainActor
final class WindowBackdrop {
    private var backdrop: NSView?
    private var tintView: NSView?
    /// `window.blur` over the material or the glass (it only reached the floating sidebar).
    private var blurView: NSView?
    private var applied: WindowLook?
    private var appliedWindowNumber = -1

    /// Makes `window` look as `look` says. Cheap when nothing changed.
    func apply(_ look: WindowLook, to window: NSWindow) {
        // The views are put back if the window lost them (it was given a new frame view), and the blur again for a new window number.
        let intact = (backdrop.map { $0.window === window } ?? true) && (tintView.map { $0.window === window } ?? true)
        guard look != applied || window.windowNumber != appliedWindowNumber || !intact else { return }
        applied = look
        appliedWindowNumber = window.windowNumber
        window.isOpaque = look.isOpaque
        window.backgroundColor = look.isOpaque ? look.opaqueColor : .clear
        remove()
        switch look.material {
            // A colour: opaque (the window's background colour), or the tint's colour and alpha with nothing under it.
            case .color: if !look.isOpaque { install(nil, in: window, tint: look.tintColor) }
            case .material: install(material(look.thickness), in: window, tint: look.tintColor)
            case .glass: install(glass(look), in: window, tint: look.light ? look.tintColor : nil)
        }
        if !look.isOpaque { installBlur(look.blur, in: window) }
        WindowBlur.setRadius(0, forWindowNumber: window.windowNumber)
        window.invalidateShadow()
    }

    private func material(_ thickness: Configuration.MaterialThickness) -> NSView {
        let view = NSVisualEffectView()
        view.material = thickness.systemMaterial(sidebar: false)
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    private func glass(_ look: WindowLook) -> NSView {
        let view = NSGlassEffectView()
        view.style = look.glass == .clear ? .clear : .regular
        view.tintColor = look.tintColor
        return view
    }

    private func install(_ view: NSView?, in window: NSWindow, tint: NSColor?) {
        guard let frame = window.contentView?.superview, let content = window.contentView else { return }
        if let view {
            view.frame = frame.bounds
            view.autoresizingMask = [.width, .height]
            frame.addSubview(view, positioned: .below, relativeTo: content)
            backdrop = view
        }
        if let tint {
            let overlay = NSView(frame: frame.bounds)
            overlay.wantsLayer = true
            overlay.layer?.backgroundColor = tint.cgColor
            overlay.autoresizingMask = [.width, .height]
            frame.addSubview(overlay, positioned: .below, relativeTo: content)
            tintView = overlay
        }
    }

    /// A full-bounds `NSView` hosting a `BackdropBlur` layer for `WindowBackdrop` and `SidebarBackdropView`.
    @MainActor
    static func makeBlurHostView(in bounds: NSRect, radius: Double, withinWindow: Bool = false) -> NSView? {
        guard let layer = BackdropBlur.makeLayer(radius: radius, withinWindow: withinWindow) else { return nil }
        let view = NSView(frame: bounds)
        view.autoresizingMask = [.width, .height]
        view.wantsLayer = true
        layer.frame = view.bounds
        layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        view.layer?.addSublayer(layer)
        return view
    }

    /// A backdrop layer of its own radius over the material (with a colour, nothing), under the tint and the content, as
    /// the sidebar has.
    private func installBlur(_ radius: Double, in window: NSWindow) {
        guard let frame = window.contentView?.superview, let content = window.contentView,
            let view = Self.makeBlurHostView(in: frame.bounds, radius: radius)
        else { return }
        if let backdrop {
            frame.addSubview(view, positioned: .above, relativeTo: backdrop)
        } else {
            frame.addSubview(view, positioned: .below, relativeTo: tintView ?? content)
        }
        blurView = view
    }

    private func remove() {
        backdrop?.removeFromSuperview()
        tintView?.removeFromSuperview()
        blurView?.removeFromSuperview()
        backdrop = nil
        tintView = nil
        blurView = nil
    }
}
