import SunsetConfig
import SunsetHost
import SunsetMetrics
import SunsetPane
import SunsetShell
import SunsetTerminal
import SwiftUI
import UniformTypeIdentifiers

/// The content of the selected tab: its panes where its split layout puts them, and the dividers between them. The panes are laid out flat (a `ForEach`
/// over the panes, each placed by its frame) rather than as nested stacks, so that a terminal's AppKit view keeps its identity while the split changes
/// around it: a pane moved or resized is not made again.
struct PaneArea: View {
    let tabs: TabsModel
    let optionAsMeta: Bool
    let translucent: Bool
    /// The terminal's background, which the panes that are not terminals are drawn on.
    let backdrop: PaneBackdrop
    /// The strip at the top that drags a window with no title bar: the panes that touch the top of the area start their text below it.
    let topInset: Double
    let layout: Configuration.Layout
    /// The sidebar is docked: the terminals are cards, `margin` from the window's edges.
    let docked: Bool
    let margin: Double
    let windowRadius: Double
    /// The corners of the area that are corners of the window (the sidebar or a tab bar covers the others).
    let windowCorners: CornerSet
    /// The window is full screen: nothing around the content but a grid's margins (`PaneAreaGeometry`).
    var fullScreen = false
    /// In a split, the margin the window bar opens above the panes while it is out: the top panes' cards start this much lower and
    /// show that much less of their content, which keeps its size (no page or terminal is laid out again for it).
    var barInset = 0.0

    private static let space = "pane-area"
    /// Where a dragged tab or pane would go while it is over the area.
    @State private var dropTarget: DropZone.Target?
    /// Option is held over the panes: the drop opens what is dragged in a new window.
    @State private var dropOpensWindow = false
    @Environment(\.accent) private var accent

    var body: some View {
        GeometryReader { proxy in
            if let item = tabs.shownItem {
                // Cards: with the sidebar docked, or when the tab is split. The space between two cards is the space between a card and the window's edge
                // (the sidebar's margin; `layout.paneGap` for a split with no docked sidebar), so the window's colour frames every card the same.
                let geometry = PaneAreaGeometry.make(
                    fullScreen: fullScreen,
                    docked: docked,
                    panes: item.panes.count,
                    measures: .init(
                        margin: margin,
                        paneGap: layout.paneGap,
                        windowRadius: windowRadius,
                        terminalRadius: layout.terminalRadius,
                        innerCornerRadius: layout.innerCornerRadius
                    )
                )
                let card = geometry.isCard
                let space = geometry.gap
                let area = CGRect(origin: .zero, size: proxy.size).insetBy(dx: geometry.inset, dy: geometry.inset)
                let bounds = area
                let radius = geometry.outerRadius
                let frames = item.layout.frames(in: bounds, gap: space)
                ZStack(alignment: .topLeading) {
                    ForEach(item.panes, id: \.self) { pane in
                        if let content = tabs.content(pane), let frame = frames[pane] {
                            let drop = item.isSplit && frame.minY <= bounds.minY + 0.5 ? barInset : 0
                            paneView(content, pane: pane, item: item, frame: frame, bounds: bounds)
                                .frame(width: frame.width, height: frame.height)
                                .frame(width: frame.width, height: max(frame.height - drop, 0), alignment: .top)
                                .modifier(
                                    TerminalCard(
                                        isCard: card,
                                        cornerRadius: radius,
                                        windowCorners: CornerSet.atCorners(of: frame, in: bounds)
                                            .intersection(windowCorners),
                                        layout: layout,
                                        stroke: PaneStrokeStyle.of(
                                            pane: pane,
                                            isCard: card,
                                            isSplit: item.isSplit,
                                            focused: item.focused,
                                            hovered: tabs.hoveredPane
                                        ),
                                        innerRadius: geometry.innerRadius
                                    )
                                )
                                .animation(layout.smooth, value: tabs.hoveredPane)
                                .animation(layout.smooth, value: item.focused)
                                .offset(x: frame.minX, y: frame.minY + drop)
                                .animation(layout.smooth, value: drop)
                        }
                    }
                    ForEach(item.layout.dividers(in: bounds, gap: space), id: \.path) { divider in
                        PaneDividerView(divider: divider, space: Self.space) { ratio in
                            tabs.setRatio(ratio, at: divider.path, in: item.id)
                        }
                    }
                }
                // The panes are placed by offsets, which do not count in layout: without this the stack is as large as one pane, and so was what accepts drops
                // (a drop on any pane but the first did nothing).
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
                .background { Color.clear.contentShape(.rect).gesture(WindowDragGesture()) }
                .overlay(alignment: .topLeading) {
                    dropPreview(item: item, bounds: bounds, space: space, radius: radius, card: card)
                    // While a drag the panes would take is under way, and none is under the pointer: each outlined.
                }
                // The tabs' previews are drawn by the window, over a floating sidebar too (`PanePreviews`).
                .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .global) }) { frame in
                    tabs.laidOut(\.paneAreaFrame, frame)
                }
                .overlay { if !tabs.showsLive { elsewhere } }
                .coordinateSpace(.named(Self.space))
                .onDrop(
                    of: [.plainText, .utf8PlainText, .fileURL],
                    delegate: PaneDropDelegate(
                        tabs: tabs,
                        frames: frames,
                        target: $dropTarget,
                        opensWindow: $dropOpensWindow
                    )
                )
                .anchorPreference(key: PaneCardShape.Key.self, value: .bounds) { bounds in
                    PaneCardShape.Area(
                        bounds: bounds,
                        card: focusedCard(item, frames, bounds: area, card: card, radius: radius)
                    )
                }
                .onChange(of: frames, initial: true) { _, new in applyInsets(new, bounds: bounds) }
                .onChange(of: topInset) { _, _ in applyInsets(frames, bounds: bounds) }
            } else {
                // No tab left, and no kept entry shown: the window stays while there are Favorites.
                Text(tabs.emptyHint)
                    .font(Design.Text.secondary)
                    .foregroundStyle(.tertiary)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .background { Color.clear.contentShape(.rect).gesture(WindowDragGesture()) }
            }
        }
    }

    /// Where a dragged tab or pane would sit: the frame the layout would give a new pane on that edge (the gap included), with the corners rounded as the
    /// cards are (wide at the window's corners, tight next to the sidebar or another card).
    @ViewBuilder
    private func dropPreview(item: Workspace.Item, bounds: CGRect, space: Double, radius: Double, card: Bool)
        -> some View
    {
        if dropOpensWindow {
            // The whole area: the drop opens a new window.
            let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
            DropVeil(shape: shape)
                .overlay {
                    Label("Open in New Window", systemImage: "macwindow.badge.plus")
                        .font(Design.Text.body.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                .frame(width: bounds.width, height: bounds.height)
                .allowsHitTesting(false)
        } else if let target = dropTarget {
            let probe = PaneID()
            let frame =
                item.layout
                .inserting(.pane(probe), beside: target.pane, edge: target.edge)
                .frames(in: bounds, gap: space)[probe] ?? target.preview
            let radii = TerminalCard.radii(
                isCard: true,
                outer: radius,
                windowCorners: CornerSet.atCorners(of: frame, in: bounds).intersection(windowCorners),
                layout: layout
            )
            let shape = UnevenRoundedRectangle(cornerRadii: radii, style: .continuous)
            DropVeil(shape: shape)
                .frame(width: frame.width, height: frame.height)
                .offset(x: frame.minX, y: frame.minY)
                .allowsHitTesting(false)
                .animation(layout.smooth, value: frame)
        }
    }

    /// The view of a pane's content; while the kept entry it belongs to is live in another window, its last picture instead (one view per content).
    @ViewBuilder
    private func paneView(_ content: any PaneContent, pane: PaneID, item: Workspace.Item, frame: CGRect, bounds: CGRect)
        -> some View
    {
        if tabs.showsLive, let making = content as? any PaneViewMaking {
            making.makeView(
                PaneViewContext(
                    focused: pane == item.focused,
                    translucent: translucent,
                    optionAsMeta: optionAsMeta,
                    topInset: frame.minY <= bounds.minY + 0.5 ? topInset : 0,
                    backdrop: backdrop
                )
            )
        } else if let terminal = tabs.terminal(pane), let surface = terminal.lastSurface {
            SurfacePreviewView(surface: surface, background: terminal.layerBackground)
        } else if let picture = content.picture {
            // A page's last snapshot, the size it was drawn at.
            Image(decorative: picture, scale: 1)
                .resizable()
                .scaledToFill()
                .frame(width: frame.width, height: frame.height, alignment: .top)
                .clipped()
                // As it is now, when this window comes to show it.
                .onAppear { content.takePicture() }
        } else {
            // Nothing pictured (settings, help, a page not drawn yet): its icon, as its preview card has (S-d).
            Color.primary.opacity(Design.Fill.faint)
                .overlay { TabIcon(model: content, showsProgress: false).opacity(Design.Fill.inkSecondary) }
        }
    }

    /// Over the last picture of an entry live in another window: dimmed, a small label, and a click brings it here.
    private var elsewhere: some View {
        ZStack {
            Color.black.opacity(Design.Fill.scrim)
            Text("Shown in another window. Click to bring it here.")
                .font(Design.Text.secondary)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Design.Space.l)
                .padding(.vertical, Design.Space.s)
                .surface(Capsule())
        }
        .contentShape(.rect)
        .onTapGesture { tabs.takeShown() }
    }

    /// Only the panes that touch the top of the area have the strip above them.
    private func applyInsets(_ frames: [PaneID: CGRect], bounds: CGRect) {
        for (pane, frame) in frames {
            tabs.terminal(pane)?.apply(topInset: frame.minY <= bounds.minY + 0.5 ? topInset : 0)
        }
    }
}
