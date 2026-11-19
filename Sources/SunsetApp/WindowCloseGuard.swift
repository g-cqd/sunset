import AppKit
import ObjectiveC
import SunsetShell

/// Asks before a window closes with unsaved edits (R6, roadmap 0023 step M-d). SwiftUI owns the window and its delegate, and
/// gives no say on closing; this stands in front of that delegate, answers `windowShouldClose` (the red button, Close Window,
/// a system tab's close button: all `performClose`), and passes everything else on untouched.
///
/// It does not see a window closed by code (`close()`): edits that go that way are kept by `OpenDocuments` and named at quit.
@MainActor
final class WindowCloseGuard: NSObject, NSWindowDelegate {
    private nonisolated(unsafe) static var key = 0

    /// SwiftUI's delegate, which this one stands in front of.
    private weak var inner: (any NSWindowDelegate)?
    private weak var tabs: TabsModel?

    private init(inner: (any NSWindowDelegate)?, tabs: TabsModel) {
        self.inner = inner
        self.tabs = tabs
    }

    /// Stands in front of the delegate of `window`, once; it lives as long as the window.
    static func install(on window: NSWindow, tabs: TabsModel) {
        if let installed = window.delegate as? Self {
            installed.tabs = tabs
            return
        }
        let made = Self(inner: window.delegate, tabs: tabs)
        unsafe objc_setAssociatedObject(window, &key, made, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        window.delegate = made
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard inner?.windowShouldClose?(sender) ?? true else { return false }
        guard let tabs, tabs.windowHoldsUnsaved else { return true }
        tabs.closeWindow { [weak sender] in sender?.close() }
        return false
    }

    // Everything else is the inner delegate's, as if this one were not here.
    // swiftlint:disable implicitly_unwrapped_optional - the signatures are NSObject's
    override func responds(to selector: Selector!) -> Bool {
        super.responds(to: selector) || (inner?.responds(to: selector) ?? false)
    }

    override func forwardingTarget(for selector: Selector!) -> Any? {
        inner
    }
    // swiftlint:enable implicitly_unwrapped_optional
}
