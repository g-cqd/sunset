import IOSurface
import SunsetConfig
import SunsetPane
import SunsetShell
import SunsetShellBridge
import SunsetTerminal
import SwiftUI

/// A floating card beside the row of a tab while the pointer is over it (`TabPreviewHost` places it): the tab's layout in miniature, each pane with
/// the last frame it drew, a page its last snapshot (a pane that has not drawn yet is a blank card). Drawn when asked; nothing is kept.
struct TabPreviewCard: View {
    let item: Workspace.Item
    let tabs: TabsModel
    let layout: Configuration.Layout

    static let width = 280.0
    private static let gap = 3.0

    /// The proportions of the area the tab is shown in, from what its panes drew (`SplitLayout.aspect(drawn:)`), kept between
    /// 110 and 220 pt; 175 when nothing has drawn yet.
    var height: Double {
        var sizes: [PaneID: CGSize] = [:]
        for pane in item.panes {
            if let surface = tabs.terminal(pane)?.lastSurface {
                sizes[pane] = CGSize(width: surface.width, height: surface.height)
            } else if let picture = tabs.content(pane)?.picture {
                sizes[pane] = CGSize(width: picture.width, height: picture.height)
            }
        }
        guard let aspect = item.layout.aspect(drawn: sizes) else { return 175 }
        return min(max(Self.width * aspect, 110), 220)
    }

    var body: some View {
        // The miniature's corners (small) nest in the card's, `Design.Space.s` inside.
        let shape = RoundedRectangle(
            cornerRadius: Design.Radius.container(holding: Design.Radius.small(layout), inset: Design.Space.s),
            style: .continuous
        )
        let custom = tabs.custom(for: item)
        // One card for every tab: this tab's content fades over the last one's while the card moves and takes its height.
        return ZStack(alignment: .topLeading) { content(custom).id(item.id).transition(.opacity) }
            .frame(width: Self.width + 2 * Design.Space.s)
            .surface(shape, shadow: .popover)
            .animation(Design.Preview.swap, value: item.id)
            .allowsHitTesting(false)
    }

    private func content(_ custom: (name: String?, icon: PaneIcon?)) -> some View {
        VStack(alignment: .leading, spacing: Design.Space.s) {
            TabLabel(
                model: tabs.content(item.focused),
                parts: TabParts(icon: true, title: true, directory: true, progress: false),
                name: custom.name,
                icon: custom.icon,
                // Not made yet (back from the session): what it is saved as, not a terminal.
                saved: tabs.pendingDescriptor(item.focused)
            )
            .padding(.horizontal, Design.Space.l)
            .padding(.top, Design.Space.m)
            miniature
                .frame(width: Self.width, height: height)
                .padding(.horizontal, Design.Space.s)
                .padding(.bottom, Design.Space.s)
        }
    }

    /// Every pane where the layout puts it, small.
    private var miniature: some View {
        let frames = item.layout.frames(in: CGRect(x: 0, y: 0, width: Self.width, height: height), gap: Self.gap)
        return ZStack(alignment: .topLeading) {
            ForEach(item.panes, id: \.self) { pane in
                if let frame = frames[pane] {
                    picture(of: pane)
                        .frame(width: frame.width, height: frame.height)
                        .clipShape(RoundedRectangle(cornerRadius: Design.Radius.small(layout), style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: Design.Radius.small(layout), style: .continuous)
                                .strokeBorder(
                                    // The pane whose part is under the pointer in the split's row, not the focused one.
                                    Color.primary.opacity(
                                        pane == tabs.hoveredPane && item.isSplit ? Design.Fill.focusLine : 0
                                    ),
                                    lineWidth: 1
                                )
                        }
                        .offset(x: frame.minX, y: frame.minY)
                }
            }
        }
        .frame(width: Self.width, height: height, alignment: .topLeading)
    }

    @ViewBuilder private func picture(of pane: PaneID) -> some View {
        if let terminal = tabs.terminal(pane), let surface = terminal.lastSurface {
            SurfacePreviewView(surface: surface, background: terminal.layerBackground)
        } else if let picture = tabs.content(pane)?.picture {
            // A page's last snapshot; cut at its bottom when the card is shorter, its top kept (seen 2026-11-17:
            // centred, the page's heading was cut).
            Color.clear
                .overlay(alignment: .top) { Image(decorative: picture, scale: 1).resizable().scaledToFill() }
                .clipped()
        } else {
            // A pane with nothing pictured (a settings tab, a page not loaded yet): its icon, so every kind has a card.
            Color.primary.opacity(Design.Fill.open)
                .overlay {
                    TabIcon(model: tabs.content(pane), saved: tabs.pendingDescriptor(pane), showsProgress: false)
                        .opacity(Design.Fill.inkSecondary)
                }
        }
    }
}
