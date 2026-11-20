import SunsetPrivate
import WebKit

/// What extension pages (background, popup, options) meet in WebKit where Firefox and Chrome differ, evened out by a script
/// of Sunset's at the start of each such page (probed on uBlock Origin from Firefox Add-ons: its background page stopped
/// on the first, its popup on the second; diary 2026-11-20-15).
///
/// Each part is a stopgap for a defect of WebKit's, listed with its repro in roadmap 0048 D ("WebKit patch candidates"):
/// when our own WebKit fixes one, its part here goes (each part names its candidate, `W1`…).
enum ExtensionPageShim {
    /// One stopgap, named by the WebKit defect it covers; it runs once for each namespace root (`browser`, `chrome`) with
    /// the helpers `root`, `kept`, `put` and `event`.
    struct Part {
        let defect: String
        let source: String
    }

    /// The parts, in the order they run. When our WebKit fixes a defect (`Engine/WebKit/patches`), its part goes.
    static let parts = [
        // W3 first: the namespaces kept before anything is added to them.
        Part(
            defect:
                "W3: WebKit's wrappers of the namespaces are collected and made again without what was added to them",
            source: """
                kept.push(root);
                for (const name in root) {
                  let space;
                  try { space = root[name]; } catch { continue; }
                  if (space && typeof space === "object") kept.push(space);
                }
                """
        ),
        Part(
            defect:
                "W1: a method called apart from its namespace (`const f = browser.runtime.getURL; f(\"\")`) gives undefined",
            source: """
                for (const space of kept.filter((object) => object !== root)) {
                  for (const key in space) {
                    let value;
                    try { value = space[key]; } catch { continue; }
                    if (typeof value !== "function") continue;
                    try {
                      Object.defineProperty(space, key, { value: value.bind(space), configurable: true, writable: true });
                    } catch {}
                  }
                }
                """
        ),
        Part(
            defect: "W2: an empty message name throws; Firefox and Chrome give \"\"",
            source: """
                if (root.i18n && typeof root.i18n.getMessage === "function") {
                  const get = root.i18n.getMessage;
                  Object.defineProperty(root.i18n, "getMessage", {
                    value: (name, ...rest) => (name ? get(name, ...rest) : ""), configurable: true, writable: true
                  });
                }
                """
        ),
        Part(
            defect: "W4: what WebKit lacks that a Firefox extension calls at its start: there, doing nothing",
            source: """
                put(root.webNavigation, "onCreatedNavigationTarget", event());
                put(root.webRequest, "handlerBehaviorChanged", async () => {});
                """
        ),
        Part(
            defect: "W8: no update is ever announced to an extension here (Sunset installs updates itself)",
            source: """
                put(root.runtime, "onUpdateAvailable", event());
                """
        )
    ]

    /// The parts in one script, each under its defect, run for each namespace root.
    static let script: String = {
        let body = parts.map { "// \($0.defect)\n\($0.source)" }.joined(separator: "\n")
        return """
            (() => {
              const roots = [globalThis.browser, globalThis.chrome].filter((r, i, all) => r && all.indexOf(r) === i);
              const kept = [];
              Object.defineProperty(globalThis, "__sunsetKeptNamespaces", { value: kept });
              const put = (space, key, value) => {
                if (space && !(key in space)) Object.defineProperty(space, key, { value, configurable: true, writable: true });
              };
              const event = () => ({ addListener() {}, removeListener() {}, hasListener() { return false; } });
              for (const root of roots) {
            \(body)
              }
            })();
            """
    }()

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
