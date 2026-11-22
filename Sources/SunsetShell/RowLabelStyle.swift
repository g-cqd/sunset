package import SwiftUI

/// A row's label: its symbol in a box of one width, centred, so that the titles of the rows under one another start at
/// one place whatever their symbols' widths; the title in the row's font.
package struct RowLabelStyle: LabelStyle {
    package init() {}

    package func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: Design.Optical.fieldGlyphToText) {
            configuration.icon
                .frame(width: Design.Size.glyphFrame, alignment: .center)
            configuration.title
        }
    }
}

extension LabelStyle where Self == RowLabelStyle {
    /// A row's label: its symbol in a box of one width.
    package static var row: RowLabelStyle {
        RowLabelStyle()
    }
}
