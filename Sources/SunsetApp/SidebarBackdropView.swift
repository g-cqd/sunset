import AppKit
import CoreFoundation
import SunsetConfig
import SunsetPrivate
import SunsetShell

/// The AppKit view of `SidebarBackdrop`. When `look.withinWindow` is true (floating sidebar and Now Playing cards),
/// `NSVisualEffectView` uses `.withinWindow` blending and a pre-commit RunLoop observer clears `CABackdropLayer.windowServerAware`
/// on both `NSVisualEffectView` and `NSGlassEffectView` so glass and material sample the web page / terminal inside the window
/// instead of the desktop behind a non-opaque `SkyWindow`.
final class SidebarBackdropView: NSView {
    var look: SidebarLook? {
        didSet {
            if look != oldValue { rebuild() }
        }
    }
    private var content: NSView?
    private var observer: CFRunLoopObserver?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    isolated deinit {
        if let observer {
            CFRunLoopRemoveObserver(CFRunLoopGetMain(), observer, .commonModes)
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        updateObserver()
        applyWithinWindowIfNeeded()
    }

    override func layout() {
        super.layout()
        content?.frame = bounds
        applyWithinWindowIfNeeded()
    }

    private func updateObserver() {
        if let observer {
            CFRunLoopRemoveObserver(CFRunLoopGetMain(), observer, .commonModes)
            self.observer = nil
        }
        guard window != nil, look?.withinWindow == true else { return }
        // Core Animation commits at order 2_000_000 in beforeWaiting | exit; running at 1_999_900 executes after
        // AppKit and SwiftUI (`SDFLayer`) finish layout/display and right before CA commits the layer tree.
        let activities = CFRunLoopActivity.beforeWaiting.rawValue | CFRunLoopActivity.exit.rawValue
        let created = CFRunLoopObserverCreateWithHandler(nil, activities, true, 1_999_900) { [weak self] _, _ in
            MainActor.assumeIsolated { self?.applyWithinWindowIfNeeded() }
        }
        if let created {
            CFRunLoopAddObserver(CFRunLoopGetMain(), created, .commonModes)
            observer = created
        }
    }

    private func applyWithinWindowIfNeeded() {
        guard look?.withinWindow == true, let layer else { return }
        BackdropBlur.setWithinWindow(true, in: layer)
    }

    private func rebuild() {
        content?.removeFromSuperview()
        content = nil
        updateObserver()
        guard let look else { return }
        let view = makeMaterialView(for: look)
        view.frame = bounds
        view.autoresizingMask = [.width, .height]
        addSubview(view)
        if look.material == .material || look.material == .glass,
            look.blur > 0,
            let blur = WindowBackdrop.makeBlurHostView(in: bounds, radius: look.blur, withinWindow: look.withinWindow)
        {
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
        applyWithinWindowIfNeeded()
    }

    private func makeMaterialView(for look: SidebarLook) -> NSView {
        switch look.material {
            case .opaque:
                let view = NSView()
                view.wantsLayer = true
                var raised = NSColor.windowBackgroundColor.cgColor
                effectiveAppearance.performAsCurrentDrawingAppearance {
                    raised =
                        (NSColor.windowBackgroundColor.blended(withFraction: Design.Raised.lighten, of: .white)
                        ?? .windowBackgroundColor)
                        .cgColor
                }
                view.layer?.backgroundColor = raised
                return view
            case .material:
                return Self.effect(
                    look.thickness.systemMaterial(sidebar: true),
                    withinWindow: look.withinWindow
                )
            case .glass:
                let glass = NSGlassEffectView()
                glass.style = look.glass == .clear ? .clear : .regular
                glass.cornerRadius = 0
                return glass
            case .fill:
                return NSView()
        }
    }

    private static func effect(_ material: NSVisualEffectView.Material, withinWindow: Bool) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = withinWindow ? .withinWindow : .behindWindow
        view.state = .active
        return view
    }
}
