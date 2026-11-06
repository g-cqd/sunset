import SwiftUI

/// SwiftUI's handle on the AppKit terminal view.
struct TerminalRepresentable: NSViewRepresentable {
    let model: TerminalModel
    var optionAsMeta: Bool

    func makeNSView(context: Context) -> TerminalNSView { TerminalNSView(model: model) }

    func updateNSView(_ view: TerminalNSView, context: Context) { view.optionAsMeta = optionAsMeta }
}
