import Foundation
import WebKit

/// The page's `Notification` (roadmap 0035 D): WebKit's own shows nothing in an app (it has no place to post to), so a script
/// at the document's start puts Sunset's in its place, in the page's world, where its scripts look for it. It asks Sunset
/// for the site's answer, to ask the person, and to show; Sunset answers by the site WebKit names, never by what the page says.
@MainActor
final class WebNotifications: NSObject, WKScriptMessageHandlerWithReply {
    static let name = "sunsetNotifications"
    static let script = """
        (() => {
          const bridge = window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.\(name);
          if (!bridge || window.top !== window) return;
          \(PageNative.prelude)
          // Shaped as WebKit's own (task t97, read in a bare WKWebView): attributes are the prototype's getters, the state
          // is this script's, and what the page could patch later (postMessage, dispatchEvent) is taken now.
          const define = Object.defineProperty;
          const send = bridge.postMessage;
          const post = (message) => Reflect.apply(send, bridge, [message]);
          const dispatch = EventTarget.prototype.dispatchEvent;
          const listen = EventTarget.prototype.addEventListener;
          const fire = (note, type) => Reflect.apply(dispatch, note, [new Event(type)]);
          const state = new WeakMap();
          const shown = new Map();
          let next = 1;
          const fields = (note, what) => {
            const found = state.get(note);
            if (!found) throw new TypeError("The Notification." + what + " can only be used on instances of Notification");
            return found;
          };
          function Notification(title, options) {
            if (!new.target) throw new TypeError("Constructor requires 'new' operator");
            if (arguments.length === 0) throw new TypeError("Not enough arguments");
            if (options != null && typeof options !== "object" && typeof options !== "function") throw new TypeError("Type error");
            options = options || {};
            const text = (value) => value === undefined ? "" : String(value);
            const dir = options.dir === undefined ? "auto" : String(options.dir);
            if (dir !== "auto" && dir !== "ltr" && dir !== "rtl") throw new TypeError("Type error");
            let icon = "";
            try { icon = options.icon === undefined ? "" : new URL(String(options.icon), location.href).href; } catch (e) {}
            const note = Reflect.construct(EventTarget, [], new.target);
            const own = {
              id: next++, title: String(title), body: text(options.body), tag: text(options.tag), icon, dir,
              lang: text(options.lang), data: options.data === undefined ? null : options.data,
              silent: options.silent === undefined || options.silent === null ? null : !!options.silent, handlers: {},
            };
            state.set(note, own);
            shown.set(own.id, note);
            (async () => {
              let ok = false;
              try { ok = await post({ kind: "show", id: own.id, title: own.title, body: own.body, tag: own.tag, icon, silent: own.silent === true }); } catch (e) {}
              fire(note, ok ? "show" : "error");
              if (ok) hearClicks();
            })();
            return note;
          }
          // The person's clicks, pulled from Sunset one at a time once a notification is shown.
          let hearing = false;
          const hearClicks = async () => {
            if (hearing) return;
            hearing = true;
            for (;;) {
              let id = null;
              try { id = await post({ kind: "clicks" }); } catch (e) {}
              if (typeof id !== "number") break;
              const note = shown.get(id);
              if (note) fire(note, "click");
            }
            hearing = false;
          };
          nativeMark(Notification, "Notification", 1);
          Object.setPrototypeOf(Notification, EventTarget);
          const prototype = Object.create(EventTarget.prototype);
          define(prototype, "constructor", { value: Notification, writable: true, enumerable: false, configurable: true });
          define(Notification, "prototype", { value: prototype, writable: false, enumerable: false, configurable: false });
          const attribute = (name) => define(prototype, name, {
            get: native(function () { return fields(this, name + " getter")[name]; }, "get " + name),
            set: undefined, enumerable: true, configurable: true,
          });
          const handler = (name) => define(prototype, name, {
            get: native(function () { return fields(this, name + " getter").handlers[name] || null; }, "get " + name),
            set: native(function (value) {
              const own = fields(this, name + " setter");
              const first = !(name in own.handlers);
              own.handlers[name] = typeof value === "function" || (typeof value === "object" && value !== null) ? value : null;
              // As an event handler attribute: one listener, in the place of the first time it was set.
              if (first) Reflect.apply(listen, this, [name.slice(2), (event) => {
                const call = own.handlers[name];
                if (typeof call === "function") Reflect.apply(call, this, [event]);
              }]);
            }, "set " + name, 1),
            enumerable: true, configurable: true,
          });
          const operation = (name, body) => define(prototype, name, { value: native(body, name), writable: true, enumerable: true, configurable: true });
          handler("onclick"); handler("onerror");
          define(prototype, "navigate", { get: native(function () { fields(this, "navigate getter"); return ""; }, "get navigate"), set: undefined, enumerable: true, configurable: true });
          for (const name of ["title", "dir", "lang", "body", "tag", "icon", "silent", "data"]) attribute(name);
          handler("onclose"); handler("ondisplay"); handler("onshow");
          operation("close", function () {
            if (!state.has(this)) throw new TypeError("Can only call Notification.close on instances of Notification");
            const own = state.get(this);
            if (!shown.has(own.id)) return;
            shown.delete(own.id);
            // The page hears of the close once Sunset has it, as it hears of the show (a race otherwise, seen once under load).
            (async () => {
              try { await post({ kind: "close", id: own.id }); } catch (e) {}
              fire(this, "close");
            })();
          });
          operation("show", function () {
            if (!state.has(this)) throw new TypeError("Can only call Notification.show on instances of Notification");
          });
          define(prototype, Symbol.toStringTag, { value: "Notification", writable: false, enumerable: false, configurable: true });
          // WebKit's `permission` is a value, not a getter: set again at each answer.
          const answered = (answer) => {
            define(Notification, "permission", { value: answer, writable: false, enumerable: true, configurable: true });
            return answer;
          };
          answered("default");
          define(Notification, "requestPermission", { writable: true, enumerable: true, configurable: true, value: native(async function (callback) {
            // As Safari: only from what the person did (a click, a key) is anybody asked.
            const activated = !!(navigator.userActivation && navigator.userActivation.isActive);
            const answer = answered(await post({ kind: "request", activated }));
            if (typeof callback === "function") callback(answer);
            return answer;
          }, "requestPermission") });
          define(window, "Notification", { value: Notification, writable: true, enumerable: false, configurable: true });
          // The Permissions API reads the same answer (WebKit's would say "prompt" whatever it is: roadmap 0045 B).
          const status = window.PermissionStatus && Object.getOwnPropertyDescriptor(PermissionStatus.prototype, "state");
          if (window.Permissions && Permissions.prototype.query && status && status.get) {
            const query = Permissions.prototype.query;
            const ours = new WeakSet();
            define(PermissionStatus.prototype, "state", { ...status, get: native(function () {
              if (!ours.has(this)) return Reflect.apply(status.get, this, []);
              const answer = Notification.permission;
              return answer === "default" ? "prompt" : answer;
            }, "get state") });
            define(Permissions.prototype, "query", { writable: true, enumerable: true, configurable: true, value: native(function (descriptor) {
              const asked = Reflect.apply(query, this, arguments);
              if (!descriptor || descriptor.name !== "notifications") return asked;
              return (async () => {
                const found = await asked;
                answered(await post({ kind: "permission" }));
                ours.add(found);
                return found;
              })();
            }, "query", 1) });
          }
          // A service worker's registration shows its notifications through Sunset too (roadmap 0046 S2): an app's web view
          // has no notification centre of its own for them. The worker's `notificationclick` is not fired.
          if (window.ServiceWorkerRegistration && ServiceWorkerRegistration.prototype.showNotification) {
            const scope = Object.getOwnPropertyDescriptor(ServiceWorkerRegistration.prototype, "scope").get;
            define(ServiceWorkerRegistration.prototype, "showNotification", { writable: true, enumerable: true, configurable: true, value: native(async function (title, options) {
              // WebKit's brand check, by one of its own getters on `this`, and its words.
              try { Reflect.apply(scope, this, []); } catch (e) { throw new TypeError("Can only call ServiceWorkerRegistration.showNotification on instances of ServiceWorkerRegistration"); }
              if (Notification.permission !== "granted") throw new TypeError("No notification permission has been granted for this origin.");
              options = options || {};
              let icon = "";
              try { icon = options.icon == null ? "" : new URL(String(options.icon), location.href).href; } catch (e) {}
              await post({ kind: "show", worker: true, id: next++, title: String(title), body: options.body == null ? "" : String(options.body), tag: options.tag == null ? "" : String(options.tag), icon, silent: options.silent === true });
            }, "showNotification", 1) });
          }
          (async () => { try { answered(await post({ kind: "permission" })); } catch (e) {} })();
        })();
        """

    private weak var content: WebContent?

    private init(content: WebContent) {
        self.content = content
    }

    /// Adds the script and its handler to the configuration's controller (after `LinkHover` gave it its own).
    static func install(on configuration: WKWebViewConfiguration, for content: WebContent) {
        PageBridge(name: name, script: script, injection: .atDocumentStart, mainFrameOnly: true, world: .page)
            .install(on: configuration, replying: WebNotifications(content: content))
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
