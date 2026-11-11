import WebKit

/// The page's view: a `WKWebView` that says when it takes the keyboard, so that a click in a page makes its pane the focused one, as a click in a
/// terminal does.
final class WebPageView: WKWebView {
    var onFocus: () -> Void = {}

    override func becomeFirstResponder() -> Bool {
        onFocus()
        return super.becomeFirstResponder()
    }
}
