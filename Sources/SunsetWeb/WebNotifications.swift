import Foundation
import WebKit

/// The page's `Notification` (roadmap 0035 D): WebKit's own shows nothing in an app (it has no place to post to), so a script
/// at the document's start puts Sunset's in its place, in the page's world, where its scripts look for it. It asks Sunset
/// for the site's answer, to ask the person, and to show; Sunset answers by the site WebKit names, never by what the page says.
@MainActor
final class WebNotifications: NSObject, WKScriptMessageHandlerWithReply {
    static let name = "sunsetNotifications"
    static let clickEvent = "sunset-notification-click"
    static let script = """
        (() => {
          const bridge = window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.\(name);
          if (!bridge || window.top !== window) return;
          let permission = "default";
          let next = 1;
          const shown = new Map();
          class Notification extends EventTarget {
            constructor(title, options) {
              super();
              if (arguments.length === 0) throw new TypeError("Failed to construct 'Notification': 1 argument required.");
              options = options || {};
              this.title = String(title);
              this.body = options.body == null ? "" : String(options.body);
              this.tag = options.tag == null ? "" : String(options.tag);
              this.icon = options.icon == null ? "" : String(options.icon);
              this.data = options.data === undefined ? null : options.data;
              this.silent = !!options.silent;
              this.onclick = null; this.onshow = null; this.onerror = null; this.onclose = null;
              const id = next++;
              shown.set(id, this);
              bridge.postMessage({ kind: "show", id, title: this.title, body: this.body })
                .then(ok => this.__fire(ok ? "show" : "error"), () => this.__fire("error"));
            }
            __fire(type) {
              const event = new Event(type);
              this.dispatchEvent(event);
              const handler = this["on" + type];
              if (typeof handler === "function") handler.call(this, event);
            }
            close() { this.__fire("close"); }
            static get permission() { return permission; }
            static get maxActions() { return 0; }
            static requestPermission(callback) {
              return bridge.postMessage({ kind: "request" }).then(answer => {
                permission = answer;
                if (typeof callback === "function") callback(answer);
                return answer;
              });
            }
          }
          addEventListener("\(clickEvent)", event => {
            const notification = shown.get(event.detail);
            if (notification) notification.__fire("click");
          });
          Object.defineProperty(window, "Notification", { value: Notification, writable: true, configurable: true });
          bridge.postMessage({ kind: "permission" }).then(answer => { permission = answer; });
        })();
        """

    private weak var content: WebContent?

    private init(content: WebContent) { self.content = content }

    /// Adds the script and its handler to the configuration's controller (after `LinkHover` gave it its own).
    static func install(on configuration: WKWebViewConfiguration, for content: WebContent) {
        let controller = configuration.userContentController
        controller.addUserScript(
            WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: true, in: .page)
        )
        controller.addScriptMessageHandler(WebNotifications(content: content), contentWorld: .page, name: name)
    }

    func userContentController(
        _ controller: WKUserContentController,
        didReceive message: WKScriptMessage
    ) async -> (Any?, String?) {
        guard let content, let fields = message.body as? [String: Any], let kind = fields["kind"] as? String else {
            return (nil, nil)
        }
        let reply = await content.notificationAsked(
            kind,
            fields,
            host: message.frameInfo.securityOrigin.host,
            mainFrame: message.frameInfo.isMainFrame,
            at: ProcessInfo.processInfo.systemUptime
        )
        return (reply, nil)
    }
}
