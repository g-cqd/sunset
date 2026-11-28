package import Foundation
internal import SunsetRuntime
package import SwiftUI
package import WebKit

/// A page document (HTML, XHTML, SVG) drawn as a page: the editor's text in a web view of its own, drawn again as it
/// changes, where it was scrolled to. The page reads only its file's folder (its styles, scripts and pictures), keeps no
/// website data, has no extension or password filling, and reaches the network only when `allowsNetwork`. A change in its
/// folder (a style saved elsewhere) draws it again. A link it follows goes to `onLink`.
package struct LocalPageView: NSViewRepresentable {
    package let text: String
    /// The file, whose folder the page may read; nil for a document of the store.
    package let file: URL?
    package let allowsNetwork: Bool
    package let onLink: @MainActor (URL) -> Void

    package init(text: String, file: URL?, allowsNetwork: Bool, onLink: @escaping @MainActor (URL) -> Void) {
        self.text = text
        self.file = file
        self.allowsNetwork = allowsNetwork
        self.onLink = onLink
    }

    package func makeCoordinator() -> LocalPageLoader {
        LocalPageLoader(onLink: onLink)
    }

    package func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        let loader = context.coordinator
        LocalPageLinks.install(in: configuration.userContentController) { [weak loader] in loader?.onLink($0) }
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = loader
        loader.view = view
        context.coordinator.show(LocalPageLoader.Wanted(text: text, file: file, allowsNetwork: allowsNetwork))
        return view
    }

    package func updateNSView(_ view: WKWebView, context: Context) {
        context.coordinator.onLink = onLink
        context.coordinator.show(LocalPageLoader.Wanted(text: text, file: file, allowsNetwork: allowsNetwork))
    }

    package static func dismantleNSView(_ view: WKWebView, coordinator: LocalPageLoader) {
        LocalPageLinks.remove(from: view.configuration.userContentController)
        coordinator.stop()
    }
}
