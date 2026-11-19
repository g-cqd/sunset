import AppKit

/// Keeps its window's title: set when it changes, and put back when something else (SwiftUI, which knows the scene by the
/// app's name) sets another. The Window menu, Mission Control, the system's tabs and accessibility read the title from the
/// window.
final class WindowTitleView: NSView {
    var title = "Sunset" {
        didSet {
            if title != oldValue { keep() }
        }
    }
    private var observation: NSKeyValueObservation?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        observation = window?.observe(\.title) { [weak self] _, _ in MainActor.assumeIsolated { self?.keep() } }
        keep()
    }

    private func keep() {
        guard let window, window.title != title else { return }
        window.title = title
    }
}
