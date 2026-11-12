import SunsetMetrics
import SunsetPane
import SwiftUI

/// A tab whose panes are split, in the sidebar: one container the size of a single tab, with its panes side by side inside it as small tabs (title only,
/// no close button on any). A click on one gives it the keyboard; the focused one of the selected tab is lit and has the hairline; each lights slightly under the pointer. A pane can be dragged out of it, onto the
/// content of a tab, and closed or sent to a tab of its own from its menu; the container itself is the handle for dragging the whole tab.
struct SidebarGroupRow: View {
    let item: Workspace.Item
    let tabs: TabsModel
    let selected: Bool
    var armed = false
    let layout: ShellSettings.Layout
    @State private var hovering = false
    @Environment(\.controlActiveState) private var activeState

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: layout.tabRadius, style: .continuous)
        let custom = tabs.custom(for: item)
        return VStack(alignment: .leading, spacing: inset) {
            // The tab's own name and icon, when it was given any: above its panes, which keep their programs' titles.
            if custom.name != nil || custom.icon != nil {
                HStack(spacing: Design.Space.xs) {
                    if let icon = custom.icon { PaneIconView(icon: icon) }
                    if let name = custom.name {
                        Text(name).font(Design.Text.detail).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                .padding(.horizontal, Design.Space.s)
            }
            HStack(spacing: inset) {
                ForEach(item.panes, id: \.self) { pane in part(pane) }
            }
        }
        .padding(inset)
        .background(shape.fill(containerHighlight))
        .overlay {
            if armed {
                shape.strokeBorder(Color.red.opacity(Design.Fill.armedLine), lineWidth: 1).allowsHitTesting(false)
            } else {
                shape.hairline(layout).opacity(selected ? 1 : 0)
            }
        }
        .contentShape(shape)
        .onHover { hovering = $0 }
        .animation(layout.smooth, value: hovering)
        .animation(layout.smooth, value: selected)
        .animation(layout.smooth, value: armed)
        .animation(layout.smooth, value: item.focused)
        .animation(layout.smooth, value: activeState)
    }

    /// The same space between the container's edge and the small tabs on all four sides, and between the small tabs: small, so that the
    /// small tabs have the room (owner, 2026-11-12); their corner nests in the row's at it.
    private var inset: Double { Design.Space.hair }

    private func part(_ pane: PaneID) -> some View {
        SidebarGroupPart(
            model: tabs.contents[pane],
            lit: selected && pane == item.focused,
            layout: layout,
            onHoverChange: { inside in
                if inside {
                    tabs.hoveredPane = pane
                } else if tabs.hoveredPane == pane {
                    tabs.hoveredPane = nil
                }
            },
            select: {
                tabs.select(item: item.id)
                tabs.focus(pane)
            }
        )
        .onDrag { tabs.itemProvider(for: .pane(pane)) }
        .contextMenu {
            Button("Rename Tab…") { tabs.beginRename(item: item.id) }
            Button("Move Pane to Its Own Tab") { tabs.detachIntoTab(pane) }
            Button("Close Pane") { tabs.requestClose(pane: pane) }
        }
    }

    private var containerHighlight: Color {
        if armed { return .red.opacity(hovering ? Design.Fill.armedHover : Design.Fill.armed) }
        return switch (selected, hovering) {
            case (true, _): .primary.opacity(activeState == .inactive ? Design.Fill.open : Design.Fill.openHover)
            case (false, true): .primary.opacity(Design.Fill.openHover)
            case (false, false): .primary.opacity(Design.Fill.open)
        }
    }
}
