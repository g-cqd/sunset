import CoreFoundation
import Foundation
import SunsetPrivate
import WebKit

/// A page's zoom (web step d): by site (remembered, or until quit) or by page, as `web.zoomScope` says; everything, or the text only.
extension WebContent {
    /// Cmd-+ (1), Cmd-- (-1).
    package func zoom(by steps: Int) { setZoom(ZoomLevels.step(from: zoom, by: steps)) }

    /// Cmd-0, or a click on the level in the address field.
    package func resetZoom() { setZoom(1) }

    package func setZoom(_ level: Double) {
        zoom = level
        if settings.zoomScope != .page {
            SiteZoom.shared.set(level, for: url?.host(), remember: settings.zoomScope == .site)
        }
        applyZoom()
        onChange()
    }

    /// The page went to another site: it takes that site's zoom (a page's own zoom stays).
    func siteChanged() {
        guard settings.zoomScope != .page else { return }
        zoom = SiteZoom.shared.level(for: url?.host())
        applyZoom()
    }

    /// The zoom on the view: the whole page, or (where WebKit has it) the text only.
    package func applyZoom() {
        guard let webView else { return }
        if settings.zoomScope != .page { zoom = SiteZoom.shared.level(for: url?.host()) }
        if settings.textOnlyZoom, WebTextZoom.set(zoom, on: webView) {
            webView.pageZoom = 1
        } else {
            WebTextZoom.set(1, on: webView)
            webView.pageZoom = zoom
        }
    }
}
