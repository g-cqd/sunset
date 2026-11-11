import SunsetConfig
import SunsetHost
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
    /// The strip at the top that drags a window with no title bar: the panes that touch the top of the area start their text below it.
    let topInset: Double
    let layout: Configuration.Layout
    /// The sidebar is docked: the terminals are cards, `margin` from the window's edges.
    let docked: Bool
    let margin: Double
    let windowRadius: Double
    /// The corners of the area that are corners of the window (the sidebar or a tab bar covers the others).
    let windowCorners: CornerSet

    private static let space = "pane-area"
    /// Where a dragged tab or pane would go while it is over the area.
    @State private var dropTarget: DropZone.Target?

    var body: some View {
        GeometryReader { proxy in
            if let item = tabs.shownItem {
                // Cards: with the sidebar docked, or when the tab is split. The space between two cards is the space between a card and the window's edge
                // (the sidebar's margin; `layout.paneGap` for a split with no docked sidebar), so the window's colour frames every card the same.
                let card = docked || item.isSplit
                let space = card ? (docked ? margin : layout.paneGap) : 0
                let bounds = CGRect(origin: .zero, size: proxy.size).insetBy(dx: space, dy: space)
                let radius = layout.terminalRadius ?? ConcentricRadius.inner(outer: windowRadius, inset: space)
                let frames = item.layout.frames(in: bounds, gap: space)
                ZStack(alignment: .topLeading) {
                    ForEach(item.panes, id: \.self) { pane in
                        if let content = tabs.content(pane), let frame = frames[pane] {
                            paneView(content, pane: pane, item: item, frame: frame, bounds: bounds)
                                .frame(width: frame.width, height: frame.height)
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
                                        )
                                    )
                                )
                                .animation(layout.smooth, value: tabs.hoveredPane)
                                .animation(layout.smooth, value: item.focused)
                                .offset(x: frame.minX, y: frame.minY)
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
                }
                .overlay(alignment: .topLeading) {
                    hoveredTabPreview
                }
                .overlay { if !tabs.showsLive { elsewhere } }
                .coordinateSpace(.named(Self.space))
                .onDrop(
                    of: [.plainText, .utf8PlainText],
                    delegate: PaneDropDelegate(tabs: tabs, frames: frames, target: $dropTarget)
                )
                .onChange(of: frames, initial: true) { _, new in applyInsets(new, bounds: bounds) }
                .onChange(of: topInset) { _, _ in applyInsets(frames, bounds: bounds) }
            } else {
                // No tab left, and no kept entry shown: the window stays while there are Favorites (R3).
                Text("No tab. \u{2318}T for a terminal")
                    .font(.callout)
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
        if let target = dropTarget {
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
            shape.fill(Color(nsColor: .controlAccentColor).opacity(0.22))
                .overlay { shape.strokeBorder(Color(nsColor: .controlAccentColor).opacity(0.7), lineWidth: 1.5) }
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
        if tabs.showsLive {
            content.makeView(
                PaneViewContext(
                    focused: pane == item.focused,
                    translucent: translucent,
                    optionAsMeta: optionAsMeta,
                    topInset: frame.minY <= bounds.minY + 0.5 ? topInset : 0
                )
            )
        } else if let terminal = tabs.terminal(pane), let surface = terminal.lastSurface {
            SurfacePreviewView(surface: surface, background: terminal.layerBackground)
        } else {
            Color.primary.opacity(0.04)
        }
    }

    /// Over the last picture of an entry live in another window: dimmed, a small label, and a click brings it here (R3, R4).
    private var elsewhere: some View {
        ZStack {
            Color.black.opacity(0.35)
            Text("Shown in another window. Click to bring it here.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.regularMaterial, in: Capsule())
        }
        .contentShape(.rect)
        .onTapGesture { tabs.takeShownEntry() }
    }

    /// Only the panes that touch the top of the area have the strip above them.
    private func applyInsets(_ frames: [PaneID: CGRect], bounds: CGRect) {
        for (pane, frame) in frames {
            tabs.terminal(pane)?.apply(topInset: frame.minY <= bounds.minY + 0.5 ? topInset : 0)
        }
    }

    /// Shows a floating thumbnail of an unselected tab's terminal screen while the pointer hovers over its tab row (`n36`).
    @ViewBuilder private var hoveredTabPreview: some View {
        if tabs.dragged == nil,
            let hoveredID = tabs.hoveredItem,
            !tabs.isSelected(hoveredID),
            let item = tabs.workspace.items.first(where: { $0.id == hoveredID }),
            let model = tabs.terminal(item.focused),
            let surface = model.lastSurface
        {
            TabPreviewCard(model: model, surface: surface, layout: layout)
                .padding(12)
                .transition(.opacity)
        }
    }
}
