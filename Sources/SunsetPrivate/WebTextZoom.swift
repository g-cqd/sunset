public import Foundation
internal import InternedStrings

/// WebKit's text-only zoom (`web.textOnlyZoom`, web step d): macOS has no public call for it. Set by name when the page answers to it; `isAvailable`
/// tells Settings whether to offer it.
public enum WebTextZoom {
    private typealias SetFactor = @convention(c) (AnyObject, Selector, Double) -> Void
    private static let setterName = #Interned("_setTextZoomFactor:")

    @MainActor
    public static func isAvailable(on view: NSObject) -> Bool { view.responds(to: NSSelectorFromString(setterName)) }

    /// Sets the text zoom of `view` (a `WKWebView`); 1 is none. Returns whether it could.
    @MainActor @discardableResult
    public static func set(_ factor: Double, on view: NSObject) -> Bool {
        let selector = NSSelectorFromString(setterName)
        guard view.responds(to: selector) else { return false }
        let function = unsafe unsafeBitCast(view.method(for: selector), to: SetFactor.self)
        function(view, selector, factor)
        return true
    }
}
