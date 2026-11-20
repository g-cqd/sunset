public import AppKit
internal import InternedStrings

/// WebKit's inspector for a page (`-[WKWebView _inspector]`, `_WKInspector`: not public API): shown docked in the page's
/// pane or in a window of its own, closed. Nothing happens where WebKit does not answer to these.
public enum WebInspector {
    @MainActor
    public static func show(_ view: NSView) {
        send(#Interned("show"), to: view)
    }

    /// Docked in the page's pane, or in a window of its own. Asked before WebKit has the inspector up, it is dropped
    /// (2026-11-20): `WebContent.showInspector` waits for it.
    @MainActor
    public static func dock(_ view: NSView, _ docked: Bool) {
        send(docked ? #Interned("attach") : #Interned("detach"), to: view)
    }

    @MainActor
    public static func close(_ view: NSView) {
        send(#Interned("close"), to: view)
    }

    @MainActor
    public static func isVisible(_ view: NSView) -> Bool {
        guard let inspector = inspector(of: view) else { return false }
        let selector = NSSelectorFromString(#Interned("isVisible"))
        guard inspector.responds(to: selector) else { return false }
        typealias Getter = @convention(c) (NSObject, Selector) -> Bool
        return unsafe unsafeBitCast(inspector.method(for: selector), to: Getter.self)(inspector, selector)
    }

    @MainActor
    private static func inspector(of view: NSView) -> NSObject? {
        let selector = NSSelectorFromString(#Interned("_inspector"))
        guard view.responds(to: selector) else { return nil }
        return view.perform(selector)?.takeUnretainedValue() as? NSObject
    }

    /// `name` sent to the page's inspector, where it answers to it.
    @MainActor
    private static func send(_ name: String, to view: NSView) {
        let selector = NSSelectorFromString(name)
        guard let inspector = inspector(of: view), inspector.responds(to: selector) else { return }
        _ = inspector.perform(selector)
    }
}
