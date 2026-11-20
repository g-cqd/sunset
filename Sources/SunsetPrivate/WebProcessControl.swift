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
        call(NSSelectorFromString(#Interned("_killWebContentProcessAndResetState")), on: webView)
    }

    /// Closes `webView`'s page now, as when it is deallocated, whatever still holds the view (`_close`). False where WebKit
    /// no longer has it: the media suspended by the caller stays the guarantee.
    @discardableResult
    public static func close(_ webView: NSObject) -> Bool {
        call(NSSelectorFromString(#Interned("_close")), on: webView)
    }

    /// Calls `selector`, which takes nothing and returns nothing, on `object`; false where it no longer answers it.
    private static func call(_ selector: Selector, on object: NSObject) -> Bool {
        guard object.responds(to: selector) else { return false }
        let call = unsafe unsafeBitCast(object.method(for: selector), to: Call.self)
        call(object, selector)
        return true
    }

    /// Has WebKit write a store's cookies to disk now (`_flushCookiesToDiskWithCompletionHandler:`), so that nothing is left
    /// to write after Sunset has gone (roadmap 0051 G: the jar was rewritten readable by every account at teardown).
    /// Returns at once where WebKit no longer has it.
    public static func flushCookies(_ cookieStore: NSObject) async {
        let selector = NSSelectorFromString(#Interned("_flushCookiesToDiskWithCompletionHandler:"))
        guard cookieStore.responds(to: selector) else { return }
        typealias Flush = @convention(c) (AnyObject, Selector, @escaping @convention(block) () -> Void) -> Void
        let call = unsafe unsafeBitCast(cookieStore.method(for: selector), to: Flush.self)
        await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
            call(cookieStore, selector) { done.resume() }
        }
    }
}
