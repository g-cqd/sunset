import SunsetPane
import SwiftUI

/// Asks for the name and the icon of the tab `tabs.renaming` names: one place for every "Rename Tab…" (the sidebar, the tab bar, the menu). An empty
/// name gives the tab its program's title back, an empty icon its own picture.
struct RenameTabAlert: ViewModifier {
    let tabs: TabsModel
    @State private var name = ""
    @State private var icon = ""

    func body(content: Content) -> some View {
        content
            .alert("Rename Tab", isPresented: isPresented) {
                TextField("Name (empty: the program's title)", text: $name)
                TextField("Icon: an emoji or a symbol's name", text: $icon)
                Button("Rename") { save() }.keyboardShortcut(.defaultAction)
                Button("Cancel", role: .cancel) { tabs.renaming = nil }
            } message: {
                Text("The icon is an emoji, or the name of an SF Symbol such as server.rack.")
            }
            .onChange(of: tabs.renaming) { _, item in
                guard let item, let current = tabs.workspace.items.first(where: { $0.id == item }) else { return }
                name = current.customTitle ?? ""
                icon = current.customIcon?.text ?? ""
            }
    }

    private var isPresented: Binding<Bool> {
        Binding(get: { tabs.renaming != nil }, set: { shown in if !shown { tabs.renaming = nil } })
    }

    private func save() {
        guard let item = tabs.renaming else { return }
        tabs.renaming = nil
        tabs.rename(item: item, to: name, icon: PaneIcon(text: icon))
    }
}
