internal import Foundation
internal import InternedStrings
internal import ObjectiveC

/// WebKit's private hand-over of a download its page menu made (Download Image, Download Video, Download Linked File):
/// `_webView:contextMenuDidCreateDownload:`, asked of the navigation delegate (probed 2026-11-20 on macOS 27.2). Not public
/// API: added to the delegate's class at run time; where WebKit no longer asks for it, nothing calls it and those items do
/// nothing, as before (the owner's note n64).
@MainActor
public enum WebDownloadHooks {
    /// What to do with the download (a `WKDownload`) made for `webView`: the delegate it was handed to, the web view, it.
    public typealias Handover = (_ delegate: AnyObject, _ webView: AnyObject, _ download: AnyObject) -> Void

    private static var installed: Set<ObjectIdentifier> = []

    /// Adds the hand-over to `delegateClass` (a `WKNavigationDelegate`'s class), once.
    public static func install(on delegateClass: AnyClass, contextMenuDownload: @escaping Handover) {
        guard installed.insert(ObjectIdentifier(delegateClass)).inserted else { return }
        let block: @convention(block) (AnyObject, AnyObject, AnyObject) -> Void = { delegate, webView, download in
            MainActor.assumeIsolated { contextMenuDownload(delegate, webView, download) }
        }
        _ = unsafe class_addMethod(
            delegateClass,
            NSSelectorFromString(#Interned("_webView:contextMenuDidCreateDownload:")),
            imp_implementationWithBlock(block),
            "v@:@@"
        )
    }
}
