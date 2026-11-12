import SunsetPrivate
import WebKit

/// Whether this macOS's WebKit has the text-only zoom, asked once of a page that is never shown (Settings hides the option without it).
@MainActor enum WebTextZoomProbe {
    static let isAvailable = WebTextZoom.isAvailable(on: WKWebView(frame: .zero))
}
