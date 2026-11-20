import AppKit
import SwiftUI

/// An AppKit view under a button, for WebKit's popover to be shown against.
struct PopupAnchor: NSViewRepresentable {
    let found: (NSView) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        found(view)
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {}
}
