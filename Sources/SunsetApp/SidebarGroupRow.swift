import SunsetConfig
import SunsetPane
import SwiftUI

/// A tab whose panes are split, in the sidebar: one container the size of a single tab, with its panes side by side inside it as small tabs (title only,
/// no close button on any). A click on one gives it the keyboard; the focused one of the selected tab is lit and has the hairline; each lights slightly under the pointer. A pane can be dragged out of it, onto the
/// content of a tab, and closed or sent to a tab of its own from its menu; the container itself is the handle for dragging the whole tab.
struct SidebarGroupRow: View {
    let item: Workspace.Item
    let tabs: TabsModel
    let selected: Bool
    let layout: Configuration.Layout
    @State private var hovering = false
    @Environment(\.controlActiveState) private var activeState

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: layout.tabRadius, style: .continuous)
        return HStack(spacing: inset) {
            ForEach(item.panes, id: \.self) { pane in part(pane) }
        }
        .padding(inset)
        .background(shape.fill(containerHighlight))
        .overlay { shape.hairline(layout).opacity(selected ? 1 : 0) }
        .contentShape(shape)
        .onHover { hovering = $0 }
        .animation(layout.smooth, value: hovering)
        .animation(layout.smooth, value: selected)
        .animation(layout.smooth, value: item.focused)
        .animation(layout.smooth, value: activeState)
    }

    /// The same space between the container's edge and the small tabs on all four sides, and between the small tabs.
    private var inset: Double { layout.tabPaddingVertical }

    private func part(_ pane: PaneID) -> some View {
        SidebarGroupPart(
            model: tabs.models[pane],
            lit: selected && pane == item.focused,
            layout: layout,
            select: {
                tabs.select(item: item.id)
                tabs.focus(pane)
            }
        )
        .onDrag { tabs.itemProvider(for: .pane(pane)) }
        .contextMenu {
            Button("Move Pane to Its Own Tab") { tabs.detachIntoTab(pane) }
            Button("Close Pane") { tabs.close(pane: pane) }
        }
    }

    private var containerHighlight: Color {
        switch (selected, hovering) {
            case (true, _): .primary.opacity(activeState == .inactive ? 0.06 : 0.1)
            case (false, true): .primary.opacity(0.07)
            case (false, false): .clear
        }
    }
}
