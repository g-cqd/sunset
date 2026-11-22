import AppKit
import SunsetCredentials
import SunsetRuntime
import SunsetShellModel
import UniformTypeIdentifiers

/// A QR code's picture chosen by the person (a screenshot of a site's setup page), read on this Mac (roadmap 0093 D):
/// its first one-time code's link is given; none found is said.
@MainActor
enum QRCodeImagePicker {
    static func read(into fill: @escaping @MainActor (String) -> Void) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.message = "Choose a picture of the QR code a site shows to set up a one-time code."
        guard panel.runModal() == .OK, let url = panel.url,
            let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else { return }
        Runtime.live.task { @MainActor in
            guard let code = (try? await QRCodeReading.codes(in: image))?.first else {
                SunsetAlerts.show(
                    SunsetAlert(
                        title: "No One-Time Code Found",
                        message: "The picture has no QR code of a one-time code.",
                        buttons: [.plain("OK")],
                        defaultButton: 0
                    )
                ) { _ in }
                return
            }
            fill(code.uri)
        }
    }
}
