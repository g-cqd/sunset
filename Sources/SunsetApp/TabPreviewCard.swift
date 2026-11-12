import IOSurface
import SunsetConfig
import SunsetPane
import SunsetShell
import SunsetShellBridge
import SunsetTerminal
import SwiftUI

/// A floating card beside the row of a tab that is not selected, while the pointer is over it (`n36`, R2): the tab's layout in miniature, each pane with
/// the last frame it drew (a pane that has not drawn yet is a blank card). Drawn when asked; nothing is kept (R2).
struct TabPreviewCard: View {
    let item: Workspace.Item
    let tabs: TabsModel
    let layout: Configuration.Layout

    static let width = 280.0
    private static let gap = 3.0

    /// The proportions of the area the tab is shown in, from what its panes drew (`SplitLayout.aspect(drawn:)`, owner note n58), kept between
    /// 110 and 220 pt; 175 when nothing has drawn yet.
    var height: Double {
        var sizes: [PaneID: CGSize] = [:]
        for pane in item.panes {
            if let surface = tabs.terminal(pane)?.lastSurface {
                sizes[pane] = CGSize(width: surface.width, height: surface.height)
            }
        }
        guard let aspect = item.layout.aspect(drawn: sizes) else { return 175 }
        return min(max(Self.width * aspect, 110), 220)
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        let custom = tabs.custom(for: item)
        VStack(alignment: .leading, spacing: 6) {
            TabLabel(
                model: tabs.content(item.focused),
                showIcon: true,
                showTitle: true,
                showDirectory: true,
                showProgress: false,
                name: custom.name,
                icon: custom.icon
            )
            .padding(.horizontal, 10)
            .padding(.top, 8)
            miniature
                .frame(width: Self.width, height: height)
                .padding(.horizontal, 6)
                .padding(.bottom, 6)
        }
        .frame(width: Self.width + 12)
        .background(.ultraThinMaterial, in: shape)
        .overlay { shape.hairline(ShellSettings.Layout(layout)) }
        .shadow(color: .black.opacity(0.28), radius: 12, y: 4)
        .allowsHitTesting(false)
    }

    /// Every pane where the layout puts it, small.
    private var miniature: some View {
        let frames = item.layout.frames(in: CGRect(x: 0, y: 0, width: Self.width, height: height), gap: Self.gap)
        return ZStack(alignment: .topLeading) {
            ForEach(item.panes, id: \.self) { pane in
                if let frame = frames[pane] {
                    picture(of: pane)
                        .frame(width: frame.width, height: frame.height)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .strokeBorder(
                                    Color.accentColor.opacity(pane == item.focused && item.isSplit ? 0.8 : 0),
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
        } else {
            Color.primary.opacity(0.06)
        }
    }
}
