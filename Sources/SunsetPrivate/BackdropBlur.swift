internal import Foundation
internal import InternedStrings
public import QuartzCore

/// A layer that blurs what is behind it, inside the window, with a radius of your choosing: the sidebar's blur (the window's own blur is `WindowBlur`, a call
/// to the window server for the whole window). It is Core Animation's backdrop layer with a Gaussian blur filter, classes that are not public API; they are
/// found by name at run time (the names stored obfuscated by InternedStrings) and `isAvailable` is false when they are not there, in which case the caller
/// uses a system material.
public enum BackdropBlur {
    private static let classes: (layer: CALayer.Type, filter: NSObject.Type)? = {
        guard let layer = NSClassFromString(#Interned("CABackdropLayer")) as? CALayer.Type,
            let filter = NSClassFromString(#Interned("CAFilter")) as? NSObject.Type
        else { return nil }
        return (layer, filter)
    }()

    public static var isAvailable: Bool { classes != nil }

    /// A backdrop layer blurring by `radius` points (0 to 100), or nil for a radius of 0 or less, or when the classes are missing.
    @MainActor
    public static func makeLayer(radius: Double) -> CALayer? {
        guard let classes, radius.isFinite, radius > 0 else { return nil }
        let layer = classes.layer.init()
        // The backdrop reads what the window server has drawn behind this layer.
        layer.setValue(true, forKey: #Interned("windowServerAware"))
        layer.setValue(#Interned("SunsetSidebar"), forKey: #Interned("groupName"))
        guard
            let filter = classes.filter.perform(
                NSSelectorFromString(#Interned("filterWithType:")),
                with: #Interned("gaussianBlur")
            )?
            .takeUnretainedValue() as? NSObject
        else { return nil }
        filter.setValue(Double(min(radius, 100)), forKey: #Interned("inputRadius"))
        layer.filters = [filter]
        return layer
    }

    @MainActor
    public static func setRadius(_ radius: Double, on layer: CALayer) {
        guard radius.isFinite, let filter = layer.filters?.first as? NSObject else { return }
        filter.setValue(Double(min(max(radius, 0), 100)), forKey: #Interned("inputRadius"))
    }
}
