public import Foundation

/// Private Click Measurement off: Safari has it off, WebKit's views on, and a page reads it on its links
/// (`HTMLAnchorElement.attributionDestination`, `attributionSourceId`), which tells Sunset from Safari. Off, a link's
/// attribution attributes are not there; probed 2026-11-19 in a bare WKWebView.
public enum WebAttribution {
    @MainActor
    public static func turnOff(on preferences: NSObject) {
        WebFeature.set("PrivateClickMeasurementEnabled", enabled: false, on: preferences)
    }
}
