import SunsetPane
import SwiftUI

/// With no sidebar, the Spaces as one button in the tab bar that names the Space shown and opens a menu of them (R4). Not
/// there while there is one Space.
struct SpacesMenuButton: View {
    let tabs: TabsModel

    var body: some View {
        if let spaces = tabs.spaces, spaces.spaces.count > 1 {
            Menu {
                ForEach(spaces.spaces, id: \.space.id) { space in
                    Button {
                        tabs.show(spaceInOrder: space)
                    } label: {
                        if space === tabs.space {
                            Label(space.space.name, systemImage: "checkmark")
                        } else {
                            Text(space.space.name)
                        }
                    }
                }
                Divider()
                Button("New Space") { tabs.newSpace() }
                Button("Edit Space\u{2026}") { tabs.edit(space: tabs.space) }
                Button("Delete Space\u{2026}", role: .destructive) { tabs.deleteSpace() }
            } label: {
                HStack(spacing: Design.Space.xs) {
                    SpaceIcon(space: tabs.space.space)
                    Text(tabs.space.space.name).font(Design.Text.secondary).lineLimit(1)
                }
            }
            .menuStyle(.borderlessButton)
            // In the bar's own colour, not the accent's: it names where one is, it is not a call to act.
            .tint(.secondary)
            .fixedSize()
            .help("Spaces")
        }
    }
}
