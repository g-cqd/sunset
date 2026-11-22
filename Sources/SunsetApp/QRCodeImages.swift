import AppKit
import SunsetCredentials
import SunsetShell
import SunsetShellModel

/// A picture of a QR code, wherever it comes from (the clipboard, a file, a drop), read on this Mac for its one-time code
/// (roadmap 0093 D); none found is said.
@MainActor
enum QRCodeImages {
    /// The clipboard's picture (`PasteboardImage`).
    static func image() -> CGImage? {
        PasteboardImage.image()
    }

    static func image(at url: URL) -> CGImage? {
        PasteboardImage.image(at: url)
    }

    /// The first one-time code in `image`; nil, said, when there is none.
    static func code(in image: CGImage) async -> OneTimeCodeURI? {
        guard let code = (try? await QRCodeReading.codes(in: image))?.first else {
            SunsetAlerts.show(
                SunsetAlert(
                    title: "No One-Time Code Found",
                    message: "The picture has no QR code of a one-time code.",
                    buttons: [.plain("OK")],
                    defaultButton: 0
                )
            ) { _ in }
            return nil
        }
        return code
    }
}
