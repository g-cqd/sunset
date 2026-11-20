import SunsetPrivate
import SunsetRuntime

/// WebKit's inspector for the page (the owner, 2026-11-20: "make it work at all time, in any kind of split tabs, and in
/// detached window modes"): docked in the page's pane, which keeps it beside the page (`WebViewHostView`), or in a window
/// of its own.
extension WebContent {
    /// Shows the inspector, docked or in its own window, once WebKit has it up (at most a second).
    package func showInspector(docked: Bool) async {
        guard let view = webView, settings.developer else { return }
        WebInspector.show(view)
        for _ in 0 ..< 50 where !WebInspector.isVisible(view) {
            await runtime.sleep(for: .milliseconds(20))
        }
        WebInspector.dock(view, docked)
    }

    /// Shown docked beside the page, or closed.
    package func toggleInspector() {
        if isInspectorVisible { return closeInspector() }
        runtime.task { await self.showInspector(docked: true) }
    }

    package func closeInspector() {
        guard let view = webView else { return }
        WebInspector.close(view)
    }

    package var isInspectorVisible: Bool {
        webView.map(WebInspector.isVisible) ?? false
    }
}
