import Foundation
import WebKit

/// A page asking to share its screen: `getDisplayMedia` wrapped in the page's world so that Sunset's sheet is asked
/// first. The sheet's answer: a Sunset tab, or what is picked in macOS's own picker, each a canvas's stream the page is
/// given; or nothing. The page pulls each frame through this handler (`frame`), an empty answer ending its track
/// (nothing of Sunset's on the page's window, and what is replaced reads as WebKit's own).
@MainActor
final class ShareWrapper: PageScriptHandler, WKScriptMessageHandlerWithReply {
    static let name = "sunsetShare"
    static let script = """
        (() => {
          const md = navigator.mediaDevices;
          const handler = window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.\(name);
          if (!md || !md.getDisplayMedia || !handler) return;
          \(PageNative.prelude)
          const send = handler.postMessage;
          const post = (m) => Reflect.apply(send, handler, [m]);
          const dispatch = EventTarget.prototype.dispatchEvent;
          const stopTrack = MediaStreamTrack.prototype.stop;
          const shares = new WeakMap();
          const end = (share) => {
            if (share.ended) return;
            share.ended = true;
            for (const t of share.stream.getTracks()) { Reflect.apply(stopTrack, t, []); Reflect.apply(dispatch, t, [new Event("ended")]); }
          };
          const pull = async (share) => {
            for (;;) {
              let b = null;
              try { b = await post({ kind: "frame" }); } catch (e) {}
              if (share.ended) return;
              if (typeof b !== "string") return end(share);
              try {
                const bitmap = await createImageBitmap(await (await fetch("data:image/jpeg;base64," + b)).blob());
                if (share.canvas.width !== bitmap.width || share.canvas.height !== bitmap.height) {
                  share.canvas.width = bitmap.width; share.canvas.height = bitmap.height;
                }
                share.ctx.drawImage(bitmap, 0, 0);
                bitmap.close();
              } catch (e) {}
            }
          };
          Object.defineProperty(MediaStreamTrack.prototype, "stop", { writable: true, enumerable: true, configurable: true, value: native(function () {
            Reflect.apply(stopTrack, this, []);
            const share = shares.get(this);
            if (share && !share.ended) { share.ended = true; post({ kind: "ended" }); }
          }, "stop") });
          const supported = MediaDevices.prototype.getSupportedConstraints;
          Object.defineProperty(MediaDevices.prototype, "getDisplayMedia", { writable: true, enumerable: true, configurable: true, value: native(async function (options) {
            // WebKit's brand check, by one of its own operations on `this`, and its words.
            try { Reflect.apply(supported, this, []); } catch (e) { throw new TypeError("Can only call MediaDevices.getDisplayMedia on instances of MediaDevices"); }
            const choice = await post({ kind: "ask" });
            if (choice !== "tab") throw new DOMException("Permission denied by the person", "NotAllowedError");
            const canvas = document.createElement("canvas");
            canvas.width = 1280; canvas.height = 720;
            const share = { canvas, ctx: canvas.getContext("2d"), stream: canvas.captureStream(30), ended: false };
            for (const t of share.stream.getTracks()) shares.set(t, share);
            pull(share);
            return share.stream;
          }, "getDisplayMedia") });
        })();
        """

    /// Adds the wrapper and its handler, unless the page is private (its window shares nothing of others').
    static func install(on configuration: WKWebViewConfiguration, for content: WebContent) -> ShareWrapper {
        let wrapper = ShareWrapper(page: content)
        PageBridge(name: name, script: script, injection: .atDocumentStart, mainFrameOnly: false, world: .page)
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
                switch await content.askShare(frameHost: message.frameInfo.securityOrigin.host) {
                    // macOS's picker, and Sunset's capture of what is picked: WebKit's own takes a screen or a window
                    // of its choosing, shows no picker, and needs the click Sunset's sheet used up.
                    case .system:
                        guard let feed = await WebShare.pickSystem() else { return ("cancel", nil) }
                        content.startShare(feed, source: UUID(), asker: Self.origin(of: message.frameInfo))
                        return ("tab", nil)
                    case .tab(let id):
                        content.startShare(from: id, asker: Self.origin(of: message.frameInfo))
                        return ("tab", nil)
                    case .cancel: return ("cancel", nil)
                }
            case "frame":
                return (await content.share?.pull(from: Self.origin(of: message.frameInfo)), nil)
            case "ended":
                content.share?.ended(by: Self.origin(of: message.frameInfo))
                return (nil, nil)
            default:
                return (nil, nil)
        }
    }

    /// The frame's origin as WebKit says it is (never what the page sends): scheme, host, port.
    static func origin(of frame: WKFrameInfo) -> String {
        let origin = frame.securityOrigin
        return "\(origin.protocol)://\(origin.host):\(origin.port)"
    }
}
