import AppKit
import WebKit

extension WebContent {
    /// Prints the page (File > Print, Cmd-P; roadmap 0029 step 4): the system's print sheet on the page's window.
    package func printPage() {
        guard let webView, let window = webView.window else { return }
        let operation = webView.printOperation(with: NSPrintInfo.shared)
        // WebKit's print view has no size of its own until it is given one.
        operation.view?.frame = webView.bounds
        operation.runModal(for: window, delegate: nil, didRun: nil, contextInfo: nil)
    }
}
