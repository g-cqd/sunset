import SunsetWebModel
import WebKit

/// "Add to Sunset" on a store's page of an extension (roadmap 0109 E, ADR-0109; the owner: "install directly through their
/// pages"): a script in Sunset's own world puts the button right after the page's title, styled as a native button; pressed, it
/// posts the page's address and Sunset installs what the page names, after the install prompt (the guard: a page's own script
/// can press the button too, as it can any element).
@MainActor
final class StoreInstallButton: PageScriptHandler, WKScriptMessageHandler {
    private static let name = "sunsetStoreInstall"
    static let script = """
        (() => {
          const store = /^(chromewebstore\\.google\\.com|chrome\\.google\\.com|addons\\.mozilla\\.org)$/;
          if (location.protocol !== "https:" || !store.test(location.hostname)) return;
          if (!/\\/detail\\/|\\/addon\\//.test(location.pathname)) return;
          const place = () => {
            if (document.querySelector("[data-sunset-install]")) return;
            const title = document.querySelector("h1");
            if (!title) return;
            const button = document.createElement("button");
            button.setAttribute("data-sunset-install", "");
            button.type = "button";
            button.textContent = "Add to Sunset";
            button.style.cssText = "display:inline-block;margin:8px 0;padding:6px 16px;border-radius:999px;border:0;" +
              "background:#0a84ff;color:#fff;font:600 14px -apple-system,system-ui;cursor:pointer";
            button.addEventListener("click", event => {
              event.preventDefault();
              webkit.messageHandlers.\(name).postMessage(location.href);
            });
            title.after(button);
          };
          // The stores draw their pages late, and again when another extension is opened in the same page.
        \(PageBridge.watching("place", root: "document.documentElement", options: "{ subtree: true, childList: true }", first: true))
        })();
        """

    static func install(on configuration: WKWebViewConfiguration, for content: WebContent) {
        PageBridge.ownWorld(name, script, at: .atDocumentEnd)
            .install(on: configuration, handler: StoreInstallButton(page: content))
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.frameInfo.isMainFrame, let address = message.body as? String, let url = URL(string: address),
            let link = ExtensionStoreLink(url), let page = content
        else { return }
        ExtensionHosts.shared.installFromStore(link, page.settings.profile)
    }
}
