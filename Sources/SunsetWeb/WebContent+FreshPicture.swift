import AppKit
import SunsetRuntime
import WebKit

extension WebContent {
    /// Its row is pointed at (the owner's note n95): a picture older than `age` is taken again. A page on screen is
    /// pictured as it is; a hidden one, whose view is in no window, is put for the time of the snapshot in a window of its
    /// own off screen, the size it last had, then taken out again. The old picture is shown until the new one comes. A
    /// page unloaded has no view: its last picture stays.
    package func refreshPicture(olderThan age: Duration) {
        guard let webView, !takingPicture else { return }
        if let taken = pictureTaken, runtime.uptime() - taken < age { return }
        guard webView.window == nil else { return takePicture() }
        let frame =
            webView.bounds.isEmpty
            ? CGRect(x: 0, y: 0, width: Self.pictureSize.width, height: Self.pictureSize.height) : webView.bounds
        let stage = NSWindow(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
        stage.isReleasedWhenClosed = false
        // Off every screen, and never shown: it only gives the page somewhere to be drawn.
        stage.setFrameOrigin(CGPoint(x: -100_000, y: -100_000))
        stage.contentView = webView
        takingPicture = true
        webView.takeSnapshot(with: nil) { [weak self, weak webView] image, _ in
            MainActor.assumeIsolated {
                if let webView, webView.window === stage { webView.removeFromSuperview() }
                stage.contentView = nil
                stage.close()
                self?.pictured(image)
            }
        }
    }

    /// A snapshot came (or none): kept as its picture, with when it was taken.
    func pictured(_ image: NSImage?) {
        takingPicture = false
        guard let image else { return }
        picture = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        pictureTaken = runtime.uptime()
    }

    /// The size a page is pictured at when it never had one on screen.
    static let pictureSize = CGSize(width: 1_024, height: 768)
}
