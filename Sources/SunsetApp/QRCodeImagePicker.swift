import AppKit
import SunsetCredentials
import SunsetRuntime
import UniformTypeIdentifiers

/// A QR code's picture chosen by the person in an open panel (a screenshot of a site's setup page).
@MainActor
enum QRCodeImagePicker {
    static func read(into fill: @escaping @MainActor (OneTimeCodeURI) -> Void) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.message = "Choose a picture of the QR code a site shows to set up a one-time code."
        guard panel.runModal() == .OK, let url = panel.url, let image = QRCodeImages.image(at: url) else { return }
        Runtime.live.task { @MainActor in
            if let code = await QRCodeImages.code(in: image) { fill(code) }
        }
    }
}
