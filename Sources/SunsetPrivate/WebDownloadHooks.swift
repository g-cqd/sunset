public import Foundation
internal import InternedStrings

/// WebKit's private hand-overs from its page menu (the owner's note n64; probed 2026-11-20 on macOS 27.2):
/// - Download Image and Download Linked File make a download and give it to the navigation delegate,
///   `_webView:contextMenuDidCreateDownload:`;
/// - Download Video gives the bytes it has to the UI delegate, `_webView:saveDataToFile:suggestedFilename:mimeType:originatingURL:`.
/// Not public API: added to the delegates' class at run time; where WebKit no longer asks for them, nothing calls them and
/// those items do nothing, as before.
@MainActor
public enum WebDownloadHooks {
    /// What to do with the download (a `WKDownload`) made for `webView`: the delegate it was handed to, the web view, it.
    public typealias Handover = (_ delegate: AnyObject, _ webView: AnyObject, _ download: AnyObject) -> Void
    /// What to do with bytes to save: the delegate, the web view, the bytes, the suggested name, the address they came from.
    public typealias SaveData = (_ delegate: AnyObject, _ webView: AnyObject, _ file: SavedBytes) -> Void

    /// Bytes WebKit hands over to be saved, as it names them.
    public struct SavedBytes: Sendable {
        public let data: Data
        public let name: String
        public let source: URL?
    }

    /// Adds the hand-overs to `delegateClass` (the class of the navigation and UI delegates), once.
    public static func install(
        on delegateClass: AnyClass,
        contextMenuDownload: @escaping Handover,
        saveData: @escaping SaveData
    ) {
        guard ClassHooks.first("downloads", on: delegateClass) else { return }
        let block: @convention(block) (AnyObject, AnyObject, AnyObject) -> Void = { delegate, webView, download in
            MainActor.assumeIsolated { contextMenuDownload(delegate, webView, download) }
        }
        ClassHooks.add(#Interned("_webView:contextMenuDidCreateDownload:"), block, "v@:@@", to: delegateClass)
        let save: @convention(block) (AnyObject, AnyObject, NSData, NSString, NSString, NSURL?) -> Void = {
            delegate,
            webView,
            data,
            name,
            _,
            source in
            let file = SavedBytes(data: data as Data, name: name as String, source: source as URL?)
            MainActor.assumeIsolated { saveData(delegate, webView, file) }
        }
        ClassHooks.add(
            #Interned("_webView:saveDataToFile:suggestedFilename:mimeType:originatingURL:"),
            save,
            "v@:@@@@@",
            to: delegateClass
        )
    }
}
