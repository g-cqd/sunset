import SunsetShell
package import SwiftUI

/// SwiftUI's handle on the AppKit terminal view.
package struct TerminalRepresentable: NSViewRepresentable {
    package let model: TerminalModel
    package var optionAsMeta: Bool
    /// The terminal's default background lets what is behind show through: the layer is not opaque then.
    package var translucent = false
    /// The pane has the keyboard: the view takes it (a split has several terminals, and only one is the first responder).
    package var focused = true

    package func makeNSView(context: Context) -> TerminalNSView {
        let view = TerminalNSView(model: model)
        model.onFocusTerminalView = { [weak view] in
            guard let view, let window = view.window else { return }
            window.makeFirstResponder(view)
        }
        return view
    }

    package func updateNSView(_ view: TerminalNSView, context: Context) {
        view.optionAsMeta = optionAsMeta
        view.layer?.isOpaque = !translucent
        // While the view is larger than the last frame (a layout that animates) the rest shows the terminal's own background, never black.
        view.layer?.backgroundColor = model.layerBackground
        if focused, !model.find.isOpen, let window = view.window,
            PaneKeyboard.takes(from: window.firstResponder, into: view)
        {
            window.makeFirstResponder(view)
        }
    }
}
