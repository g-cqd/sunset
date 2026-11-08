public import AppKit
internal import InternedStrings

/// The corner radius of a window, in points, as AppKit's own window frame reports it. There is no public API for it: SwiftUI's `ConcentricRectangle`
/// takes a container shape you give it, it does not read the window's. The frame view answers `_cornerRadius`; the name is looked up at run time (decoded
/// by InternedStrings) and a macOS that no longer answers makes this return nil, so the caller falls back to the radius measured on macOS 27.0.1 (16 pt).
public enum WindowCornerRadius {
    @MainActor public static func of(_ window: NSWindow) -> Double? {
        let name = #Interned("_cornerRadius")
        guard let frame = window.contentView?.superview ?? Optional(window),
            frame.responds(to: NSSelectorFromString(name)),
            let value = frame.value(forKey: name) as? NSNumber
        else { return nil }
        let radius = value.doubleValue
        return radius.isFinite && radius >= 0 ? radius : nil
    }
}
