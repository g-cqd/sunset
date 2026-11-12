import SunsetPane
package import SwiftUI

package struct PaneGlyphView: View {
    let glyph: PaneGlyph

    package init(glyph: PaneGlyph) { self.glyph = glyph }

    package var body: some View {
        switch glyph {
            case .tab(let glyph): TabGlyphView(glyph: glyph)
            case .symbol(let name): PaneIconView(icon: .symbol(name))
            case .initial(let letter):
                Text(letter)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 15, height: 15)
                    .background(
                        RoundedRectangle(cornerRadius: 3.5, style: .continuous).strokeBorder(.secondary, lineWidth: 1)
                    )
                    .frame(width: 18)
        }
    }
}
