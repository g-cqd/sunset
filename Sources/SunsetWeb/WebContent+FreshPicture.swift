import AppKit
import SunsetRuntime
import WebKit

extension WebContent {
    /// A snapshot of the page as it is drawn now (J), its whole width: for a window that shows it while another draws it.
    package func takePicture() {
        pictureIsFull = true
        takePicture(width: nil)
    }

    /// A snapshot `width` points wide (nil: as drawn), kept as its `picture` when it arrives. A preview card's is a fraction
    /// of the page's: a full snapshot kept for every tab, taken every two seconds while text changed, was the audit's
    /// PERF-02/MEM-01.
    func takePicture(width: Double?) {
        guard let webView, webView.window != nil, webView.bounds.width > 0, webView.bounds.height > 0 else { return }
        takingPicture = true
        let configuration = WKSnapshotConfiguration()
        if let width, width < webView.bounds.width { configuration.snapshotWidth = NSNumber(value: width) }
        webView.takeSnapshot(with: configuration) { [weak self] image, _ in
            MainActor.assumeIsolated { self?.pictured(image) }
        }
    }

    /// The width it is pictured again at, as the picture it has now: its whole width or a preview's.
    var repictureWidth: Double? {
        pictureIsFull ? nil : Self.previewPictureWidth
    }

    /// Its row is pointed at (the owner's note n95): a picture older than `age` is taken again. A page on screen is
    /// pictured as it is; a hidden one, whose view is in no window, is put for the time of the snapshot in a window of its
    /// own off screen, the size it last had, then taken out again. The old picture is shown until the new one comes. A
    /// page unloaded has no view: its last picture stays.
    package func refreshPicture(olderThan age: Duration) {
        guard let webView, !takingPicture else { return }
        if let taken = pictureTaken, runtime.uptime() - taken < age { return }
        guard webView.window == nil else { return takePicture(width: repictureWidth) }
        let frame =
            webView.bounds.isEmpty
            ? CGRect(x: 0, y: 0, width: Self.pictureSize.width, height: Self.pictureSize.height) : webView.bounds
        let stage = NSWindow(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
        stage.isReleasedWhenClosed = false
        // Off every screen, and never shown: it only gives the page somewhere to be drawn.
        stage.setFrameOrigin(CGPoint(x: -100_000, y: -100_000))
        stage.contentView = webView
        takingPicture = true
        let configuration = WKSnapshotConfiguration()
        configuration.snapshotWidth = NSNumber(value: min(repictureWidth ?? frame.width, frame.width))
        webView.takeSnapshot(with: configuration) { [weak self, weak webView] image, _ in
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
