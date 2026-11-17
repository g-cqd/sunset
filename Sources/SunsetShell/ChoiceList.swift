package import SwiftUI

/// The rows of a list of choices, with the states of the command bar study: the pointer over a row a light fill, a row pressed a darker one, the
/// keyboard's row the accent's fill. The pointer does not move the keyboard's row: a list that changes under a still pointer keeps its selection.
package struct ChoiceList: View {
    let rows: [ChoiceRow]
    let selection: Int
    let radius: Double
    /// Between two rows: the sidebar's between two tabs, where the caller has it (the owner, 2026-11-17).
    let spacing: Double
    /// A row was clicked: its first action.
    let activate: (Int) -> Void

    package init(
        rows: [ChoiceRow],
        selection: Int,
        radius: Double,
        spacing: Double = Design.Space.hair,
        activate: @escaping (Int) -> Void
    ) {
        self.rows = rows
        self.selection = selection
        self.radius = radius
        self.spacing = spacing
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
                // Rows close to the panel's edge (the owner, 2026-11-17: 2 pt less than before).
                .padding(Design.Space.xs)
            }
            .bouncesOnlyWhenScrolling()
            .scrollIndicators(.never)
            .onChange(of: selection) { _, now in
                if rows.indices.contains(now) { proxy.scrollTo(rows[now].id) }
            }
        }
        // As tall as its rows (a scroll view takes all the room it is offered), up to nine of them.
        .frame(height: Self.height(rows: min(rows.count, 9), spacing: spacing))
    }

    package static let rowHeight = 36.0

    /// The list's height for `rows` rows: each row (`rowHeight` less its own gap), the spaces between them, the padding.
    /// - Parameters:
    ///   - rows: How many rows show.
    ///   - spacing: Between two rows.
    /// - Returns: The height in points.
    package static func height(rows: Int, spacing: Double) -> Double {
        let row = rowHeight - Design.Space.hair
        return Double(rows) * row + Double(max(rows - 1, 0)) * spacing + 2 * Design.Space.xs
    }
}
