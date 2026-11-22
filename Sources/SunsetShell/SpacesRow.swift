import AppKit
import SunsetPane
package import SunsetRuntime
package import SwiftUI
import UniformTypeIdentifiers

/// The Spaces as a row of icons at the bottom of the sidebar, beside the +: a click shows the Space in this window; the
/// one shown is marked. Not there while there is one Space. A Space's menu opens its editor, moves it in the order and
/// deletes it.
package struct SpacesRow: View {
    @Environment(\.runtime) var runtime

    let tabs: TabsModel
    @Environment(\.accent) private var accent
    @Environment(\.sidebarButtonMetrics) private var metrics
    @Environment(\.surfaceStyle) private var surface
    /// The Space whose icon is being dragged.
    @State private var dragged: Space.ID?

    /// Dots always (`sidebar.spaces` "dots"), the shown Space's too.
    let onlyDots: Bool

    package init(tabs: TabsModel, onlyDots: Bool = false) {
        self.tabs = tabs
        self.onlyDots = onlyDots
    }

    package var body: some View {
        if let spaces = tabs.spaces, spaces.spaces.count > 1 {
            // Centred between the buttons at the two ends: icons; dots, the shown Space's icon among them, once they do not
            // fit; dots always when asked (`sidebar.spaces`); scrolled only when even those do not fit.
            ViewThatFits(in: .horizontal) {
                if !onlyDots { icons(spaces, dots: false) }
                icons(spaces, dots: true)
                ScrollView(.horizontal, showsIndicators: false) { icons(spaces, dots: true) }
                    .bouncesOnlyWhenScrolling()
            }
            .animation(animation, value: tabs.space.space.id)
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Spaces")
        }
    }

    private func icons(_ spaces: SpacesModel, dots: Bool) -> some View {
        HStack(spacing: dots ? 0 : Design.Space.hair) {
            ForEach(Array(spaces.spaces.enumerated()), id: \.element.space.id) { index, space in
                icon(
                    space,
                    at: index,
                    in: spaces,
                    dot: dots && (space !== tabs.space || onlyDots)
                )
            }
        }
    }

    /// A Space's icon: a button of the sidebar, of the size and with the hover of the + and the Library; the one shown has
    /// the selection's fill under it, as a selected tab. As a dot (`dot`), a narrower button: the shown one's dot larger and
    /// bright, the others small and dim.
    private func icon(_ space: SpaceModel, at index: Int, in spaces: SpacesModel, dot: Bool) -> some View {
        let shown = space === tabs.space
        return SidebarIconButton(
            help: index < 9 ? "\(space.space.name) (\u{2325}\u{2318}\(index + 1))" : space.space.name,
            menu: AnyView(menu(space, at: index, in: spaces)),
            action: { tabs.show(spaceInOrder: space) },
            label: {
                Group {
                    if dot {
                        Circle()
                            .frame(
                                width: shown ? Design.SpaceDot.shown : Design.SpaceDot.size,
                                height: shown ? Design.SpaceDot.shown : Design.SpaceDot.size
                            )
                            .opacity(shown ? 1 : Design.Fill.inkSecondary)
                    } else {
                        SpaceIcon(space: space.space)
                    }
                }
                // The shown one in white (primary), as the selected tab's ink; the others as the bar's other glyphs.
                .foregroundStyle(shown ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
                // Something in it asked for attention while no window showed it (S-e).
                .overlay(alignment: .topTrailing) {
                    if space.needsAttention && !shown {
                        Circle().fill(accent.color).frame(width: Design.Symbol.mark, height: Design.Symbol.mark)
                            .offset(x: Design.Space.xs, y: -Design.Space.xs)
                            .accessibilityLabel("Needs attention")
                    }
                }
            }
        )
        .environment(\.sidebarButtonMetrics, dot ? metrics.narrowed(to: Design.SpaceDot.button) : metrics)
        .background(
            Color.primary.opacity(shown && !dot ? Design.Fill.selected : 0),
            in: .rect(cornerRadius: metrics.radius, style: .continuous)
        )
        .accessibilityLabel(space.space.name)
        .accessibilityAddTraits(shown ? .isSelected : [])
        // Dragged onto another's place, the others making room as it passes.
        .opacity(dragged == space.space.id ? Design.Fill.inkSecondary : 1)
        .onDrag {
            dragged = space.space.id
            // Let go anywhere (outside the row, or cancelled): the drag ends when no button is down.
            runtime.task { @MainActor in
                while NSEvent.pressedMouseButtons != 0 { await runtime.sleep(for: .milliseconds(100)) }
                dragged = nil
            }
            return NSItemProvider(object: space.space.id.uuidString as NSString)
        }
        .onDrop(
            of: [.text],
            delegate: SpaceDrop(target: space.space.id, dragged: $dragged, spaces: spaces, animation: animation)
        )
    }

    private var animation: Animation? {
        surface.layout.smooth
    }

    @ViewBuilder
    private func menu(_ space: SpaceModel, at index: Int, in spaces: SpacesModel) -> some View {
        Button("Edit Space\u{2026}") { tabs.edit(space: space) }
        Button("Move Left") { spaces.move(space, to: index - 1) }.disabled(index == 0)
        Button("Move Right") { spaces.move(space, to: index + 1) }.disabled(index == spaces.spaces.count - 1)
        Divider()
        Button("Delete Space\u{2026}", role: .destructive) { tabs.deleteSpace(space) }
    }
}
