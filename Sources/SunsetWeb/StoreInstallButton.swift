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
          // The Chrome Web Store only: Firefox Add-ons is shown Firefox, and its own button links to the package, which
          // Sunset installs (roadmap 0109 E).
          if (location.protocol !== "https:") return;
          if (!/^(chromewebstore\\.google\\.com|chrome\\.google\\.com)$/.test(location.hostname)) return;
          const press = event => {
            event.preventDefault();
            event.stopImmediatePropagation();
            webkit.messageHandlers.\(name).postMessage(location.href);
          };
          // The store's own button, in any language (its text names Chrome: "Add to Chrome", "Zu Chrome hinzufügen"…),
          // disabled for a browser it does not know: enabled, "Chrome" said "Sunset", its look kept; pressed, Sunset installs.
          const take = button => {
            button.setAttribute("data-sunset-install", "");
            button.addEventListener("click", press, true);
          };
          const place = () => {
            // The store is one page that changes its address (seen 2026-11-20: a search result under the button): only an
            // extension's page has it; elsewhere the button of Sunset's goes, and the store's is left as it is.
            if (!/\\/detail\\//.test(location.pathname)) {
              for (const ours of document.querySelectorAll("[data-sunset-own]")) ours.remove();
              return;
            }
            for (const taken of document.querySelectorAll("[data-sunset-install]")) {
              if (taken.disabled) taken.disabled = false;
              taken.removeAttribute("aria-disabled");
            }
            if (document.querySelector("[data-sunset-install]")) return;
            const theirs = [...document.querySelectorAll("button")].find(b => /Chrome/.test(b.textContent || ""));
            if (theirs) {
              const walker = document.createTreeWalker(theirs, NodeFilter.SHOW_TEXT);
              for (let node = walker.nextNode(); node; node = walker.nextNode()) {
                node.textContent = node.textContent.replace(/Chrome/g, "Sunset");
              }
              theirs.disabled = false;
              theirs.removeAttribute("aria-disabled");
              take(theirs);
              return;
            }
            const title = document.querySelector("h1");
            if (!title) return;
            const button = document.createElement("button");
            button.setAttribute("data-sunset-own", "");
            button.type = "button";
            button.textContent = "Add to Sunset";
            button.style.cssText = "all:initial;display:inline-flex;align-items:center;justify-content:center;" +
              "box-sizing:border-box;height:36px;padding:0 20px;border-radius:18px;white-space:nowrap;" +
              "background:#0a84ff;color:#fff;font:600 14px -apple-system,system-ui;cursor:pointer";
            take(button);
            title.after(button);
          };
          // The store draws its page late, and again (its button too) when another item is opened in the same page.
        \(PageBridge.watching(
            "place",
            root: "document.documentElement",
            options: #"{ subtree: true, childList: true, attributes: true, attributeFilter: ["disabled"] }"#,
            first: true
        ))
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
