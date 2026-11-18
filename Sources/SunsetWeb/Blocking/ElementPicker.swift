package import WebKit

/// Picks an element of a page to hide for good (roadmap 0022 W-e): the element under the pointer is outlined, a click
/// picks it, Escape gives up. Runs in Sunset's own script world: the page's scripts cannot see it nor answer for it.
@MainActor
package enum ElementPicker {
    /// A selector for an element: its id when it is unique, else its place under its nearest such ancestor or the body.
    static let selectorFunction = """
        const sunsetSelector = el => {
          const parts = [];
          while (el && el.nodeType === 1 && el !== document.documentElement) {
            if (el.id && /^[A-Za-z][\\w-]*$/.test(el.id) && document.querySelectorAll('#' + el.id).length === 1) {
              parts.unshift('#' + el.id);
              break;
            }
            let part = el.localName;
            const parent = el.parentElement;
            if (parent && el.localName !== 'body') {
              const same = [...parent.children].filter(c => c.localName === el.localName);
              if (same.length > 1) part += ':nth-of-type(' + (same.indexOf(el) + 1) + ')';
            }
            parts.unshift(part);
            if (el.localName === 'body') break;
            el = parent;
          }
          return parts.join(' > ');
        };
        """

    private static let picker =
        selectorFunction + """
            return await new Promise(resolve => {
              const box = document.createElement('div');
              box.style.cssText = 'position:fixed;pointer-events:none;z-index:2147483647;outline:2px solid #e8590c;'
                + 'background:rgba(232,89,12,0.15);border-radius:2px;';
              let current = null;
              const move = e => {
                current = e.target;
                const r = current.getBoundingClientRect();
                Object.assign(box.style, {
              left: r.left + 'px', top: r.top + 'px', width: r.width + 'px', height: r.height + 'px'
            });
              };
              const done = value => {
                removeEventListener('mousemove', move, true);
                removeEventListener('click', click, true);
                removeEventListener('keydown', key, true);
                box.remove();
                resolve(value);
              };
              const click = e => {
                e.preventDefault();
                e.stopPropagation();
                done(current && current !== document.body ? sunsetSelector(current) : null);
              };
              const key = e => { if (e.key === 'Escape') { e.preventDefault(); done(null); } };
              addEventListener('mousemove', move, true);
              addEventListener('click', click, true);
              addEventListener('keydown', key, true);
              document.documentElement.appendChild(box);
            });
            """

    /// Lets the person pick an element of the page.
    /// - Returns: its selector; nil when they gave up.
    package static func pick(in view: WKWebView) async -> String? {
        let result = try? await view.callAsyncJavaScript(picker, arguments: [:], in: nil, contentWorld: .defaultClient)
        guard let selector = result as? String, !selector.isEmpty else { return nil }
        return selector
    }

    /// The selector of the element an expression of the page names (tests).
    static func selector(of expression: String, in view: WKWebView) async throws -> String? {
        let script = selectorFunction + "return sunsetSelector(\(expression));"
        let result = try await view.callAsyncJavaScript(script, arguments: [:], in: nil, contentWorld: .defaultClient)
        return result as? String
    }
}
