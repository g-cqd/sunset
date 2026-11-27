internal import Foundation
internal import InternedStrings
public import QuartzCore

/// A layer that blurs what is behind it, inside the window, with a radius of your choosing: the sidebar's blur (the window's own blur is `WindowBlur`, a call
/// to the window server for the whole window). It is Core Animation's backdrop layer with a Gaussian blur filter, classes that are not public API; they are
/// found by name at run time (the private class and selector names stored obfuscated by InternedStrings) and `isAvailable` is false when they are not there,
/// in which case the caller uses a system material.
public enum BackdropBlur {
    private static let classes: (layer: CALayer.Type, filter: NSObject.Type)? = {
        guard let layer = NSClassFromString(#Interned("CABackdropLayer")) as? CALayer.Type,
            let filter = NSClassFromString(#Interned("CAFilter")) as? NSObject.Type
        else { return nil }
        return (layer, filter)
    }()

    public static var isAvailable: Bool {
        classes != nil
    }

    /// A backdrop layer blurring by `radius` points (0 to 100), or nil for a radius of 0 or less, or when the classes are missing.
    /// - Parameters:
    ///   - radius: blur radius in points (clamped to 0...100).
    ///   - withinWindow: when `true`, samples only layers inside the window (`windowServerAware = false`) instead of what lies behind the window.
    /// - Returns: the configured backdrop layer, or `nil` when `radius` is not positive or private backdrop classes are unavailable.
    @MainActor
    public static func makeLayer(radius: Double, withinWindow: Bool = false) -> CALayer? {
        guard let classes, radius.isFinite, radius > 0 else { return nil }
        let layer = classes.layer.init()
        layer.setValue(!withinWindow, forKey: #Interned("windowServerAware"))
        layer.setValue("SunsetSidebar", forKey: "groupName")
        guard
            let filter = classes.filter.perform(
                NSSelectorFromString(#Interned("filterWithType:")),
                with: "gaussianBlur"
            )?
            .takeUnretainedValue() as? NSObject
        else { return nil }
        filter.setValue(Double(min(radius, 100)), forKey: "inputRadius")
        layer.filters = [filter]
        return layer
    }

    @MainActor
    public static func setRadius(_ radius: Double, on layer: CALayer) {
        guard radius.isFinite, let filter = layer.filters?.first as? NSObject else { return }
        filter.setValue(Double(min(max(radius, 0), 100)), forKey: "inputRadius")
    }
}

/// Core Animation's private `CABackdropLayer.windowServerAware` property: in a non-opaque window (`isOpaque = false`),
/// AppKit and SwiftUI (`SDFLayer`) set `windowServerAware = true` on `NSVisualEffectView` and `NSGlassEffectView` backdrop
/// layers, causing floating surfaces inside the window to sample the desktop / windows behind Sunset instead of the web page
/// or terminal underneath. Clearing `windowServerAware` makes those backdrop layers blend against in-window content.
extension BackdropBlur {
    @MainActor
    public static func setWithinWindow(_ withinWindow: Bool, in root: CALayer) {
        let key = #Interned("windowServerAware")
        let wanted = !withinWindow
        func walk(_ layer: CALayer) {
            if let classes, layer.isKind(of: classes.layer),
                (layer.value(forKey: key) as? Bool) != wanted
            {
                layer.setValue(wanted, forKey: key)
            }
            for sub in layer.sublayers ?? [] { walk(sub) }
        }
        walk(root)
    }
}
