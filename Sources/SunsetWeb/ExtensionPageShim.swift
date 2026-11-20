import SunsetPrivate
import WebKit

/// What extension pages (background, popup, options) meet in WebKit where Firefox and Chrome differ, evened out by a script
/// of Sunset's at the start of each such page (probed on uBlock Origin from Firefox Add-ons: its background page stopped
/// on the first, its popup on the second; diary 2026-11-20-15).
///
/// Each part is a stopgap for a defect of WebKit's, listed with its repro in roadmap 0048 D ("WebKit patch candidates"):
/// when our own WebKit fixes one, its part here goes (each part names its candidate, `W1`…).
enum ExtensionPageShim {
    static let script = """
        (() => {
          const roots = [globalThis.browser, globalThis.chrome].filter((r, i, all) => r && all.indexOf(r) === i);
          // W3: WebKit's wrappers of the namespaces are collected and made again without what was added to them; kept.
          const kept = [];
          Object.defineProperty(globalThis, "__sunsetKeptNamespaces", { value: kept });
          const put = (space, key, value) => {
            if (space && !(key in space)) {
              Object.defineProperty(space, key, { value, configurable: true, writable: true });
            }
          };
          const event = () => ({ addListener() {}, removeListener() {}, hasListener() { return false; } });
          for (const root of roots) {
            kept.push(root);
            for (const name in root) {
              let space;
              try { space = root[name]; } catch { continue; }
              if (!space || typeof space !== "object") continue;
              kept.push(space);
              // W1: a method called apart from its namespace (`const f = browser.runtime.getURL; f("")`) gives undefined.
              for (const key in space) {
                let value;
                try { value = space[key]; } catch { continue; }
                if (typeof value !== "function") continue;
                try {
                  Object.defineProperty(space, key, { value: value.bind(space), configurable: true, writable: true });
                } catch {}
              }
            }
            // W2: an empty message name throws; Firefox and Chrome give "".
            const i18n = root.i18n;
            if (i18n && typeof i18n.getMessage === "function") {
              const get = i18n.getMessage;
              Object.defineProperty(i18n, "getMessage", {
                value: (name, ...rest) => (name ? get(name, ...rest) : ""), configurable: true, writable: true
              });
            }
            // W4: what WebKit lacks that a Firefox extension calls at its start: there, doing nothing.
            put(root.webNavigation, "onCreatedNavigationTarget", event());
            put(root.webRequest, "handlerBehaviorChanged", async () => {});
          }
        })();
        """

    /// The script in every extension page of `configuration`'s controller, and Safari's features on there as in pages
    /// (W5: `requestIdleCallback`, off in an app's views).
    @MainActor
    static func install(on configuration: WKWebExtensionController.Configuration) {
        let pages = configuration.webViewConfiguration ?? WKWebViewConfiguration()
        pages.userContentController.addUserScript(
            WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        )
        SafariParity.turnOn(on: pages.preferences)
        configuration.webViewConfiguration = pages
    }
}
