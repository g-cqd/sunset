import SunsetConfig
import SunsetShell
import SwiftUI

/// The sections of the sidebar (roadmap 0031): the Library, the Documents heading among the tabs, the order of the documents.
extension SettingsView {
    @ViewBuilder
    func sectionControls(for id: String) -> some View {
        switch id {
            case "sidebar.library":
                VStack(alignment: .leading, spacing: Design.Space.xs) {
                    Toggle("Library at the foot of the sidebar", isOn: config.binding(\.sidebar.library))
                    Text(
                        "Its glyph widens the sidebar by a rail: Tabs, Documents, History, Downloads. The panel on the other side "
                            + "has the same lists (Cmd-Y)."
                    )
                    .font(Design.Text.detail).foregroundStyle(.secondary)
                }
            case "sidebar.documents":
                VStack(alignment: .leading, spacing: Design.Space.xs) {
                    Toggle("Documents among the tabs", isOn: config.binding(\.sidebar.documents))
                    Text(
                        "A Documents heading between the Favorites and the tabs: a document's row is its tab while it is open."
                    )
                    .font(Design.Text.detail).foregroundStyle(.secondary)
                }
            case "sidebar.documentSort":
                Picker("Order of documents", selection: config.binding(\.sidebar.documentSort)) {
                    ForEach(DocumentSort.allCases, id: \.self) { sort in
                        Text(sort.title).tag(Configuration.Sidebar.DocumentSort(rawValue: sort.rawValue) ?? .changed)
                    }
                }
            default: EmptyView()
        }
    }
}
