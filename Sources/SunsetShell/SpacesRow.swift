import SunsetPane
package import SwiftUI

/// The Spaces as a row of icons at the bottom of the sidebar, beside the + (R4; roadmap 0021 step S-b): a click shows the
/// Space in this window; the one shown is marked. Not there while there is one Space. A Space's menu opens its editor,
/// moves it in the order and deletes it.
package struct SpacesRow: View {
    let tabs: TabsModel
    @Environment(\.accent) private var accent
    @Environment(\.surfaceStyle) private var surface

    package init(tabs: TabsModel) { self.tabs = tabs }

    package var body: some View {
        if let spaces = tabs.spaces, spaces.spaces.count > 1 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Design.Space.hair) {
                    ForEach(Array(spaces.spaces.enumerated()), id: \.element.space.id) { index, space in
                        icon(space, at: index, in: spaces)
                    }
                }
                .padding(.horizontal, Design.Space.xs)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Spaces")
        }
    }

    private func icon(_ space: SpaceModel, at index: Int, in spaces: SpacesModel) -> some View {
        let shown = space === tabs.space
        return Button {
            tabs.show(spaceInOrder: space)
        } label: {
            SpaceIcon(space: space.space)
                .frame(width: 26, height: 24)
                .background(
                    shown ? AnyShapeStyle(accent.color.opacity(Design.Fill.target)) : AnyShapeStyle(Color.clear),
                    in: .rect(cornerRadius: Design.Radius.small(surface.layout))
                )
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .help(index < 9 ? "\(space.space.name) (\u{2325}\u{2318}\(index + 1))" : space.space.name)
        .accessibilityLabel(space.space.name)
        .accessibilityAddTraits(shown ? .isSelected : [])
        .contextMenu {
            Button("Edit Space\u{2026}") { tabs.edit(space: space) }
            Button("Move Left") { spaces.move(space, to: index - 1) }.disabled(index == 0)
            Button("Move Right") { spaces.move(space, to: index + 1) }.disabled(index == spaces.spaces.count - 1)
            Divider()
            Button("Delete Space\u{2026}", role: .destructive) { tabs.deleteSpace(space) }
        }
    }
}
