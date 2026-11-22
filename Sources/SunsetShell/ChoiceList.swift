package import SwiftUI

/// The rows of a list of choices, with their states: the pointer over a row a light fill, a row pressed a darker one, the keyboard's row the
/// accent's fill. The pointer does not move the keyboard's row: a list that changes under a still pointer keeps its selection.
package struct ChoiceList: View {
    let rows: [ChoiceRow]
    let selection: Int
    let radius: Double
    /// Between two rows, and from the rows to the list's edge.
    let spacing: Double
    let inset: Double
    /// A row was clicked: its first action.
    let activate: (Int) -> Void

    /// The most it may be tall (the room left in a small window); its rows scroll in it.
    let maxHeight: Double

    package init(
        rows: [ChoiceRow],
        selection: Int,
        radius: Double,
        spacing: Double = Design.Space.hair,
        inset: Double = Design.Space.s,
        maxHeight: Double = .infinity,
        activate: @escaping (Int) -> Void
    ) {
        self.maxHeight = maxHeight
        self.rows = rows
        self.selection = selection
        self.radius = radius
        self.spacing = spacing
        self.inset = inset
        self.activate = activate
    }

    package var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: spacing) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                        Button {
                            activate(index)
                        } label: {
                            ChoiceRowView(row: row, selected: index == selection)
                        }
                        .buttonStyle(ChoiceRowStyle(selected: index == selection, radius: radius))
                        .id(row.id)
                    }
                }
                .padding(inset)
            }
            .bouncesOnlyWhenScrolling()
            .scrollIndicators(.never)
            .onChange(of: selection) { _, now in
                if rows.indices.contains(now) { proxy.scrollTo(rows[now].id) }
            }
        }
        // As tall as its rows (a scroll view takes all the room it is offered), up to nine of them.
        .frame(height: min(maxHeight, Self.height(rows: min(rows.count, 9), spacing: spacing, inset: inset)))
    }

    package static let rowHeight = 36.0

    /// The list's height for `rows` rows: each row (`rowHeight` less its own gap), the spaces between them, the padding.
    /// - Parameters:
    ///   - rows: How many rows show.
    ///   - spacing: Between two rows.
    ///   - inset: From the rows to the list's edge.
    /// - Returns: The height in points.
    package static func height(rows: Int, spacing: Double, inset: Double) -> Double {
        let row = rowHeight - Design.Space.hair
        return Double(rows) * row + Double(max(rows - 1, 0)) * spacing + 2 * inset
    }
}
