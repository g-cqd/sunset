import SunsetPane
import SwiftUI

/// What the app proposes when the selected tab is dropped on its own content: the other tabs, to pick the one to put on the other side.
struct SplitChoiceList: View {
    let tabs: TabsModel
    let choice: SplitChoice

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Split with…").font(.caption).foregroundStyle(.secondary).padding(.horizontal, 8).padding(.top, 4)
            ForEach(tabs.candidates(for: choice)) { item in
                Button {
                    tabs.complete(choice, with: item.id)
                } label: {
                    Text(tabs.models[item.focused]?.title ?? "Sunset")
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .frame(minWidth: 180, maxWidth: 280)
    }
}
