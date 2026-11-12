package import SwiftUI

/// The rows of a list of choices, with the states of the command bar study: the pointer over a row a light fill, a row pressed a darker one, the
/// keyboard's row the accent's fill. The pointer does not move the keyboard's row: a list that changes under a still pointer keeps its selection.
package struct ChoiceList: View {
    let rows: [ChoiceRow]
    let selection: Int
    let radius: Double
    /// A row was clicked: its first action.
    let activate: (Int) -> Void

    package init(rows: [ChoiceRow], selection: Int, radius: Double, activate: @escaping (Int) -> Void) {
        self.rows = rows
        self.selection = selection
        self.radius = radius
        self.activate = activate
    }

    package var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 2) {
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
                .padding(6)
            }
            .scrollIndicators(.never)
            .onChange(of: selection) { _, now in
                if rows.indices.contains(now) { proxy.scrollTo(rows[now].id) }
            }
        }
        // As tall as its rows (a scroll view takes all the room it is offered), up to nine of them.
        .frame(height: min(Double(rows.count), 9) * Self.rowHeight + 12)
    }

    package static let rowHeight = 36.0
}
