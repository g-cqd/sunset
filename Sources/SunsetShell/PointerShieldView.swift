package import SwiftUI

/// A surface that the pointer does not pass through (owner, 2026-11-13, t232): clicks, scrolls and hover stop at it, and the
/// views beneath in its window ignore the pointer while it is there. A click on it runs `onClick`.
package struct PointerShieldView: NSViewRepresentable {
    let onClick: () -> Void

    package init(onClick: @escaping () -> Void) { self.onClick = onClick }

    package func makeNSView(context: Context) -> NSView {
        let view = PointerShieldNSView()
        view.onClick = onClick
        return view
    }

    package func updateNSView(_ view: NSView, context: Context) {
        (view as? PointerShieldNSView)?.onClick = onClick
    }
}
