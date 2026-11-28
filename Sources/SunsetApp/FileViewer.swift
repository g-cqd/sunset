import AVKit
import PDFKit
import SunsetPane
import SwiftUI
import WebKit

/// The system's viewer for a file only looked at: PDFKit's for a PDF (zoom, search, selection), WebKit's for a picture (fit
/// to the pane, a click for its own size, animated ones playing; no script, only the file readable), and AVKit's player
/// for a sound or a film. A file that cannot be read shows nothing.
struct FileViewer: NSViewRepresentable {
    let url: URL
    let viewed: FileViewed

    func makeNSView(context: Context) -> NSView {
        switch viewed {
            case .pdf:
                let view = PDFView()
                view.autoScales = true
                view.backgroundColor = .clear
                view.document = PDFDocument(url: url)
                return view
            case .picture:
                let configuration = WKWebViewConfiguration()
                configuration.websiteDataStore = .nonPersistent()
                configuration.defaultWebpagePreferences.allowsContentJavaScript = false
                let view = WKWebView(frame: .zero, configuration: configuration)
                view.underPageBackgroundColor = .clear
                view.loadFileURL(url, allowingReadAccessTo: url)
                return view
            case .media:
                let view = AVPlayerView()
                view.player = AVPlayer(url: url)
                view.controlsStyle = .floating
                return view
        }
    }

    func updateNSView(_ view: NSView, context: Context) {}

    static func dismantleNSView(_ view: NSView, coordinator: ()) {
        (view as? AVPlayerView)?.player?.pause()
    }
}
