import Foundation
import WebKit

/// A page asking to share its screen (ADR-0082): `getDisplayMedia` wrapped in the page's world so that Sunset's sheet is
/// asked first. The sheet's answer: a Sunset tab, or what is picked in macOS's own picker (ADR-0085), each a canvas's stream
/// the page is given, its frames drawn by Sunset; or nothing. The functions Sunset draws and ends through are named with
/// a token of this page's, which its own scripts cannot guess.
@MainActor
final class ShareWrapper: NSObject, WKScriptMessageHandlerWithReply {
    static let name = "sunsetShare"
    private weak var content: WebContent?
    let token = UUID().uuidString.replacingOccurrences(of: "-", with: "")

    var frameFunction: String {
        "__sunsetShareFrame_" + token
    }
    var endFunction: String {
        "__sunsetShareEnd_" + token
    }

    private init(content: WebContent) {
        self.content = content
    }

    var script: String {
        """
        (() => {
          const md = navigator.mediaDevices;
          if (!md || !md.getDisplayMedia) return;
          const post = (m) => webkit.messageHandlers.\(Self.name).postMessage(m);
          let canvas = null, ctx = null, stream = null;
          window["\(frameFunction)"] = async (b) => {
            if (!ctx) return 0;
            const blob = await (await fetch("data:image/jpeg;base64," + b)).blob();
            const bitmap = await createImageBitmap(blob);
            if (canvas.width !== bitmap.width || canvas.height !== bitmap.height) {
              canvas.width = bitmap.width; canvas.height = bitmap.height;
            }
            ctx.drawImage(bitmap, 0, 0);
            bitmap.close();
            return 1;
          };
          window["\(endFunction)"] = () => {
            if (!stream) return;
            for (const t of stream.getTracks()) { t.__sunsetStop(); t.dispatchEvent(new Event("ended")); }
            stream = null; ctx = null;
          };
          md.getDisplayMedia = async function (options) {
            const choice = await post({ kind: "ask" });
            if (choice !== "tab") throw new DOMException("Permission denied by the person", "NotAllowedError");
            canvas = document.createElement("canvas");
            canvas.width = 1280; canvas.height = 720;
            ctx = canvas.getContext("2d");
            stream = canvas.captureStream(30);
            for (const t of stream.getTracks()) {
              t.__sunsetStop = t.stop.bind(t);
              t.stop = () => { t.__sunsetStop(); post({ kind: "ended" }); };
            }
            return stream;
          };
        })();
        """
    }

    /// Adds the wrapper and its handler, unless the page is private (its window shares nothing of others').
    static func install(on configuration: WKWebViewConfiguration, for content: WebContent) -> ShareWrapper {
        let wrapper = ShareWrapper(content: content)
        PageBridge(name: name, script: wrapper.script, injection: .atDocumentStart, mainFrameOnly: false, world: .page)
            .install(on: configuration, replying: wrapper)
        return wrapper
    }

    func userContentController(
        _ controller: WKUserContentController,
        didReceive message: WKScriptMessage
    ) async -> (Any?, String?) {
        guard let content, let body = message.body as? [String: Any], let kind = body["kind"] as? String else {
            return (nil, nil)
        }
        switch kind {
            case "ask":
                switch await content.askShare() {
                    // macOS's picker, and Sunset's capture of what is picked (ADR-0085): WebKit's own takes a
                    // screen or a window of its choosing, shows no picker, and needs the click Sunset's sheet used up.
                    case .system:
                        guard let feed = await WebShare.pickSystem() else { return ("cancel", nil) }
                        content.startShare(feed, source: UUID())
                        return ("tab", nil)
                    case .tab(let id):
                        content.startShare(from: id)
                        return ("tab", nil)
                    case .cancel: return ("cancel", nil)
                }
            case "ended":
                content.share?.stop(.stopped, tellPage: false)
                return (nil, nil)
            default:
                return (nil, nil)
        }
    }
}
