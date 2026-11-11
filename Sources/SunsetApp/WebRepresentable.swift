import SwiftUI
import WebKit

/// SwiftUI's handle on a page's view. The view belongs to the content, not to this: it is put in a container that SwiftUI may make again (when a split
/// changes) without the page loading again.
struct WebRepresentable: NSViewRepresentable {
    let content: WebContent
    let focused: Bool

    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        attach(to: container)
        return container
    }

    func updateNSView(_ container: NSView, context: Context) {
        attach(to: container)
        let page = content.view()
        if focused, let window = page.window,
            window.firstResponder === window.contentView || window.firstResponder == nil
        {
            window.makeFirstResponder(page)
        }
    }

    private func attach(to container: NSView) {
        let page = content.view()
        guard page.superview !== container else { return }
        page.removeFromSuperview()
        page.frame = container.bounds
        page.autoresizingMask = [.width, .height]
        container.addSubview(page)
    }
}
