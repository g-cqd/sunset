package import Observation
import SunsetPrivate
import WebKit

/// Find in a page (web step d): what is looked for, the options, the count and the current match. WebKit's private find when it has it (all matches
/// highlighted, "3 of 12"), else the public one (found or not).
@MainActor @Observable
package final class PageFind {
    package var isOpen = false
    package var text = ""
    package var matchCase = false
    package var startsWith = false
    /// How many matches (nil: not known yet, or the public find, which does not count) and which is current (from 0).
    package private(set) var count: Int?
    package private(set) var index: Int?
    /// Raised to put the keyboard in the field.
    package private(set) var focusRequest = 0

    @ObservationIgnored private weak var webView: WKWebView?
    @ObservationIgnored private var engine: WebFind?

    package init() {}

    func attach(_ view: WKWebView) {
        webView = view
        engine = WebFind(view: view)
        engine?.onResult = { [weak self] count, index in
            self?.count = count
            self?.index = count == 0 ? nil : index
        }
    }

    /// Cmd-F: the bar opens, or takes the keyboard again, with what was looked for selected.
    package func open() {
        isOpen = true
        focusRequest += 1
        if !text.isEmpty { search() }
    }

    /// Cmd-E: what is selected in the page becomes what is looked for.
    package func useSelection() {
        webView?
            .evaluateJavaScript("window.getSelection().toString()") { [weak self] value, _ in
                MainActor.assumeIsolated {
                    guard let self, let selected = value as? String, !selected.isEmpty else { return }
                    self.text = selected
                    self.isOpen = true
                    self.search()
                }
            }
    }

    /// What is looked for changed: the current match stays where it is when it still matches (WebKit's "no index change"), so that typing does not
    /// move on by one match per letter.
    package func restart() { search(keepingIndex: true) }

    /// The next match (or the previous): from the current one; with new text, the first from the top of what is shown.
    package func search(backwards: Bool = false, keepingIndex: Bool = false) {
        guard let webView, !text.isEmpty else {
            clearResult()
            return
        }
        if let engine {
            var options: WebFind.Options = []
            if !matchCase { options.insert(.caseInsensitive) }
            if startsWith { options.insert(.atWordStarts) }
            if backwards { options.insert(.backwards) }
            if keepingIndex { options.insert(.noIndexChange) }
            engine.find(text, options: options)
            return
        }
        let configuration = WKFindConfiguration()
        configuration.caseSensitive = matchCase
        configuration.backwards = backwards
        configuration.wraps = true
        webView.find(text, configuration: configuration) { [weak self] result in
            MainActor.assumeIsolated {
                self?.count = result.matchFound ? nil : 0
                self?.index = nil
            }
        }
    }

    /// Done or Escape: the highlights go.
    package func close() {
        isOpen = false
        clearResult()
        // The yellow mark on the current match goes only with the selection it is drawn on.
        webView?.evaluateJavaScript("window.getSelection().removeAllRanges()", completionHandler: nil)
    }

    private func clearResult() {
        count = nil
        index = nil
        engine?.hide()
    }

    /// "3 of 12", "Not found", or nothing.
    package var status: String {
        guard !text.isEmpty, let count else { return "" }
        guard count > 0 else { return "Not found" }
        return index.map { "\($0 + 1) of \(count)" } ?? "\(count) found"
    }
}
