import SwiftUI

/// SwiftUI's handle on the AppKit terminal view.
struct TerminalRepresentable: NSViewRepresentable {
    let model: TerminalModel
    var optionAsMeta: Bool
    /// The terminal's default background lets what is behind show through: the layer is not opaque then.
    var translucent = false
    /// The pane has the keyboard: the view takes it (a split has several terminals, and only one is the first responder).
    var focused = true

    func makeNSView(context: Context) -> TerminalNSView { TerminalNSView(model: model) }

    func updateNSView(_ view: TerminalNSView, context: Context) {
        view.optionAsMeta = optionAsMeta
        view.layer?.isOpaque = !translucent
        // While the view is larger than the last frame (a layout that animates) the rest shows the terminal's own background, never black.
        view.layer?.backgroundColor = model.layerBackground
        if focused, let window = view.window, window.firstResponder !== view { window.makeFirstResponder(view) }
    }
}
