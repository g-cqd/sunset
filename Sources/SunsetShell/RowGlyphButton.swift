import SunsetMetrics
package import SwiftUI

/// A small button of a row, as a tab's close button is: a glyph on nothing at rest, a rounded fill under the pointer,
/// darker pressed. The address field's lock, Copy and Reload are these.
package struct RowGlyphButton<Glyph: View>: View {
    let help: String
    let action: () -> Void
    let glyph: Glyph

    package init(help: String, action: @escaping () -> Void, @ViewBuilder glyph: () -> Glyph) {
        self.help = help
        self.action = action
        self.glyph = glyph()
    }

    package var body: some View {
        Button(action: action) {
            glyph.font(.system(size: Design.Symbol.badge, weight: Design.Symbol.weight))
        }
        .buttonStyle(.quietGlyph)
        .help(help)
    }
}

extension RowGlyphButton where Glyph == Image {
    /// A button of one symbol.
    package init(symbol: String, help: String, action: @escaping () -> Void) {
        self.init(help: help, action: action) { Image(systemName: symbol) }
    }
}
