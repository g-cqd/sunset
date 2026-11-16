import SunsetPane
import SwiftUI

/// A Space's editor (roadmap 0021 step S-c): its name, and its icon chosen as a row's is (R3's popover).
struct SpaceEditor: View {
    let tabs: TabsModel
    let space: SpaceModel
    @State private var name = ""
    @FocusState private var naming: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
                .focused($naming)
                .onSubmit { tabs.editingSpace = nil }
                .onChange(of: name) { _, typed in tabs.rename(.space(space.space.id), to: typed) }
                .padding([.horizontal, .top], Design.Space.xl)
                .accessibilityLabel("Space name")
            IconPopover(tabs: tabs, row: .space(space.space.id))
        }
        .frame(width: 340)
        .onAppear {
            name = space.space.name
            naming = true
        }
    }
}
