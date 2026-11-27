import SunsetMetrics
import SwiftUI

/// A row's end button: the close button's size, its symbol's size and weight, its fill under the pointer. A device in use is red.
struct RowEndButton: View {
    let symbol: String
    let help: String
    var live = false
    let layout: ShellSettings.Layout
    let action: () -> Void
    @State private var over = false

    var body: some View {
        SwiftUI.Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: Design.Symbol.badge, weight: Design.Symbol.weight))
                .foregroundStyle(live ? AnyShapeStyle(.red) : AnyShapeStyle(over ? .primary : .secondary))
                .rowEndFace(layout, lit: over)
        }
        .buttonStyle(.plain)
        .focusable(false)
        .keptHover($over)
        .help(help)
        .accessibilityLabel(help)
    }
}
