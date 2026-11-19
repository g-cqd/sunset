public import Foundation
internal import InternedStrings
internal import ObjectiveC

/// Ends a page's web process for a force reload (the owner's note n50): WebKit's private
/// `_killWebContentProcessAndResetState`, looked up by name. Where WebKit no longer has it, false: the caller makes the
/// page's view again instead.
@MainActor
public enum WebProcessControl {
    private typealias Call = @convention(c) (AnyObject, Selector) -> Void

    /// Ends `webView`'s process; WebKit says the process ended (`webViewWebContentProcessDidTerminate`) before this returns.
    public static func end(_ webView: NSObject) -> Bool {
        let selector = NSSelectorFromString(#Interned("_killWebContentProcessAndResetState"))
        guard webView.responds(to: selector) else { return false }
        let call = unsafe unsafeBitCast(webView.method(for: selector), to: Call.self)
        call(webView, selector)
        return true
    }

    /// Closes `webView`'s page now, as when it is deallocated, whatever still holds the view (`_close`). False where WebKit
    /// no longer has it: the media suspended by the caller stays the guarantee.
    @discardableResult
    public static func close(_ webView: NSObject) -> Bool {
        let selector = NSSelectorFromString(#Interned("_close"))
        guard webView.responds(to: selector) else { return false }
        let call = unsafe unsafeBitCast(webView.method(for: selector), to: Call.self)
        call(webView, selector)
        return true
    }
}
