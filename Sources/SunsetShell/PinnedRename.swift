import SunsetPane
import SwiftUI

/// The name of a pinned entry, asked beside its tile (a tile shows an icon only).
struct PinnedRename: View {
    let tabs: TabsModel
    let entry: Favorites.Entry
    @State private var name = ""
    @FocusState private var focused: Bool

    var body: some View {
        TextField("Name", text: $name)
            .textFieldStyle(.roundedBorder)
            .focused($focused)
            .frame(width: 220)
            .padding(Design.Space.xl)
            .onSubmit { tabs.rename(.node(entry.id), to: name) }
            .onAppear {
                name = tabs.name(of: .node(entry.id))
                focused = true
            }
            .accessibilityLabel("Pinned entry name")
    }
}
