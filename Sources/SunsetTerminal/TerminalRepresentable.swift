package import SwiftUI

/// SwiftUI's handle on the AppKit terminal view.
package struct TerminalRepresentable: NSViewRepresentable {
    package let model: TerminalModel
    package var optionAsMeta: Bool
    /// The terminal's default background lets what is behind show through: the layer is not opaque then.
    package var translucent = false
    /// The pane has the keyboard: the view takes it (a split has several terminals, and only one is the first responder).
    package var focused = true

    package func makeNSView(context: Context) -> TerminalNSView { TerminalNSView(model: model) }

    package func updateNSView(_ view: TerminalNSView, context: Context) {
        view.optionAsMeta = optionAsMeta
        view.layer?.isOpaque = !translucent
        // While the view is larger than the last frame (a layout that animates) the rest shows the terminal's own background, never black.
        view.layer?.backgroundColor = model.layerBackground
        if focused, let window = view.window, window.firstResponder !== view { window.makeFirstResponder(view) }
    }
}
