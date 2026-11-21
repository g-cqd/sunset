import SunsetPane
import SunsetShell
import SunsetShellModel
import SwiftUI

/// Asks for the name and the icon of the tab `tabs.renaming` names: one place for every "Rename Tab…" (the sidebar, the tab
/// bar, the menu), in Sunset's look (the owner's note n73). An empty name gives the tab its program's title back, an empty
/// icon its own picture. Return renames, Escape cancels.
struct RenameTabAlert: ViewModifier {
    let tabs: TabsModel
    @State private var name = ""
    @State private var icon = ""
    @Environment(\.surfaceStyle) private var surface
    @FocusState private var nameFocused: Bool

    func body(content: Content) -> some View {
        content
            .overlay {
                if tabs.renaming != nil {
                    ZStack {
                        Color.black.opacity(Design.Fill.veil).ignoresSafeArea().contentShape(.rect).onTapGesture {}
                        panel
                    }
                    .transition(.opacity)
                }
            }
            .onChange(of: tabs.renaming) { _, item in
                guard let item, let current = tabs.workspace.items.first(where: { $0.id == item }) else { return }
                name = current.customTitle ?? ""
                icon = current.customIcon?.text ?? ""
            }
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: Design.Space.l) {
            Text("Rename Tab").font(Design.Text.body.weight(.semibold))
            TextField("Name (empty: the program's title)", text: $name).textFieldStyle(.roundedBorder)
                .focused($nameFocused)
                .onAppear { nameFocused = true }
            TextField("Icon: an emoji or a symbol's name", text: $icon).textFieldStyle(.roundedBorder)
            Text("The icon is an emoji, or the name of an SF Symbol such as server.rack.")
                .font(Design.Text.detail).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            HStack(spacing: Design.Space.s) {
                Spacer()
                Button("Cancel", role: .cancel) { tabs.renaming = nil }.keyboardShortcut(.cancelAction)
                Button("Rename") { save() }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(Design.Space.xl)
        .frame(width: Design.Width.panel, alignment: .leading)
        .surface(surface.panelShape, shadow: .popover)
    }

    private func save() {
        guard let item = tabs.renaming else { return }
        tabs.renaming = nil
        tabs.rename(item: item, to: name, icon: PaneIcon(text: icon))
    }
}
