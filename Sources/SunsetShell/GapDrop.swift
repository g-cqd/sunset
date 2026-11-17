import SunsetMetrics
import SwiftUI
import UniformTypeIdentifiers

/// The gap between two rows of the sidebar as a place to drop (the owner, 2026-11-17, roadmap 0038 F): "the spacing between
/// tabs […] might be one interactive target for dropping that only highlights when hovered during drag and drop". It is as
/// tall as the rows' spacing (nothing at the ends of a section), and takes a drop over a band reaching a quarter into the
/// rows beside it; a line in its middle shows only while a drop it would take is over it.
struct GapDrop: View {
    let tabs: TabsModel
    let layout: ShellSettings.Layout
    let place: SectionDrop
    /// As tall as the rows' spacing between two rows; nothing at a section's top or bottom.
    var between = true
    @State private var targeted = false
    @Environment(\.accent) private var accent

    /// How far into the rows beside it the gap takes a drop.
    private var reach: Double { Design.oneLineHeight(layout, height: Design.Size.tabRow) / 4 }

    var body: some View {
        let height = between ? layout.tabSpacing : 0
        Color.clear
            .frame(height: height)
            .overlay {
                Color.clear
                    .frame(height: height + 2 * reach)
                    .contentShape(.rect)
                    .overlay {
                        if targeted {
                            Capsule().fill(accent.color).frame(height: Design.Space.hair)
                                .padding(.horizontal, Design.Space.xs)
                                .transition(.opacity)
                        }
                    }
                    .onDrop(
                        of: [.plainText, .utf8PlainText],
                        delegate: Delegate(tabs: tabs, place: place, targeted: $targeted)
                    )
                    // Only while tabs are dragged: else the rows' edges are the rows' (clicks, hover).
                    .allowsHitTesting(DragUnderWay.shared.origin != nil)
            }
            .zIndex(1)
            .animation(layout.smooth, value: targeted)
            .accessibilityHidden(true)
    }

    private struct Delegate: DropDelegate {
        let tabs: TabsModel
        let place: SectionDrop
        @Binding var targeted: Bool

        func validateDrop(info: DropInfo) -> Bool { tabs.canDropDragged(in: place) }
        func dropEntered(info: DropInfo) { targeted = validateDrop(info: info) }
        func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: targeted ? .move : .cancel) }
        func dropExited(info: DropInfo) { targeted = false }

        func performDrop(info: DropInfo) -> Bool {
            targeted = false
            return tabs.dropDragged(in: place)
        }
    }
}
