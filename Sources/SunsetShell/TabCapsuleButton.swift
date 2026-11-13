package import SwiftUI

/// A button of the tab bar's row of capsules (owner, 2026-11-13): the button is the whole component, a circle as tall as the row's
/// tabs and field, with the field's fill and hairline at rest, lighter under the pointer, darker pressed.
package struct TabCapsuleButton: View {
    let symbol: String
    let help: String
    let action: () -> Void

    package init(symbol: String, help: String, action: @escaping () -> Void) {
        self.symbol = symbol
        self.help = help
        self.action = action
    }

    package var body: some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: Design.Symbol.row, weight: .regular))
        }
        .buttonStyle(TabCapsuleButtonStyle())
        .help(help)
    }
}
