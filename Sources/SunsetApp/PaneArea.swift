import SunsetConfig
import SunsetPane
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

    private static let space = "pane-area"
    /// Where a dragged tab or pane would go while it is over the area.
    @State private var dropTarget: DropZone.Target?

    var body: some View {
        GeometryReader { proxy in
            let bounds = CGRect(origin: .zero, size: proxy.size)
            if let item = tabs.workspace.selectedItem {
                let frames = item.layout.frames(in: bounds, gap: layout.paneGap)
                ZStack(alignment: .topLeading) {
                    ForEach(item.panes, id: \.self) { pane in
                        if let model = tabs.models[pane], let frame = frames[pane] {
                            TerminalRepresentable(
                                model: model,
                                optionAsMeta: optionAsMeta,
                                translucent: translucent,
                                focused: pane == item.focused
                            )
                            .frame(width: frame.width, height: frame.height)
                            .overlay { if item.isSplit, pane == item.focused { focusRing } }
                            .offset(x: frame.minX, y: frame.minY)
                        }
                    }
                    ForEach(item.layout.dividers(in: bounds, gap: layout.paneGap), id: \.path) { divider in
                        PaneDividerView(divider: divider, space: Self.space, layout: layout) { ratio in
                            tabs.setRatio(ratio, at: divider.path, in: item.id)
                        }
                    }
                }
                .overlay(alignment: .topLeading) { dropPreview }
                .coordinateSpace(.named(Self.space))
                .onDrop(
                    of: [.plainText, .utf8PlainText],
                    delegate: PaneDropDelegate(tabs: tabs, frames: frames, target: $dropTarget)
                )
                .onChange(of: frames, initial: true) { _, new in applyInsets(new, bounds: bounds) }
                .onChange(of: topInset) { _, _ in applyInsets(frames, bounds: bounds) }
            }
        }
    }

    /// The half of a pane that a dragged tab or pane would take.
    @ViewBuilder private var dropPreview: some View {
        if let preview = dropTarget?.preview {
            RoundedRectangle(cornerRadius: layout.tabRadius, style: .continuous)
                .fill(Color.accentColor.opacity(0.22))
                .overlay {
                    RoundedRectangle(cornerRadius: layout.tabRadius, style: .continuous)
                        .strokeBorder(Color.accentColor.opacity(0.7), lineWidth: 1.5)
                }
                .frame(width: preview.width, height: preview.height)
                .offset(x: preview.minX, y: preview.minY)
                .allowsHitTesting(false)
                .animation(layout.smooth, value: preview)
        }
    }

    /// A thin line inside the focused pane of a split, so that one can tell which has the keyboard.
    private var focusRing: some View {
        Rectangle()
            .strokeBorder(Color.accentColor.opacity(0.5), lineWidth: 1)
            .allowsHitTesting(false)
    }

    /// Only the panes that touch the top of the area have the strip above them.
    private func applyInsets(_ frames: [PaneID: CGRect], bounds: CGRect) {
        for (pane, frame) in frames {
            tabs.models[pane]?.apply(topInset: frame.minY <= bounds.minY + 0.5 ? topInset : 0)
        }
    }
}
