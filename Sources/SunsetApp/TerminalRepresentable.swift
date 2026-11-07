import SwiftUI

/// SwiftUI's handle on the AppKit terminal view.
struct TerminalRepresentable: NSViewRepresentable {
    let model: TerminalModel
    var optionAsMeta: Bool
    /// The terminal's default background lets what is behind show through: the layer is not opaque then.
    var translucent = false

    func makeNSView(context: Context) -> TerminalNSView { TerminalNSView(model: model) }

    func updateNSView(_ view: TerminalNSView, context: Context) {
        view.optionAsMeta = optionAsMeta
        view.layer?.isOpaque = !translucent
    }
}
