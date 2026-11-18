import SunsetPane
import SunsetShell
import SwiftUI
import UniformTypeIdentifiers

/// Receives a tab or a pane dragged over the content of a tab: while it moves, the pane under it and the edge nearest it are worked out (`DropZone`) and
/// published for the overlay; the drop does what the overlay showed. What is dragged is known from the start (`TabsModel.dragged`), so no data is loaded.
struct PaneDropDelegate: DropDelegate {
    let tabs: TabsModel
    let frames: [PaneID: CGRect]
    @Binding var target: DropZone.Target?

    func validateDrop(info: DropInfo) -> Bool { tabs.hasDrag || info.hasItemsConforming(to: [.fileURL]) }

    func dropEntered(info: DropInfo) { update(info) }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        // Files from outside: no half of a pane is shown, they are typed or opened where they fall.
        guard tabs.hasDrag else { return DropProposal(operation: .copy) }
        update(info)
        return DropProposal(operation: target == nil ? .cancel : .move)
    }

    func dropExited(info: DropInfo) { target = nil }

    func performDrop(info: DropInfo) -> Bool {
        defer { target = nil }
        guard tabs.hasDrag else {
            return Feedback.dropped(FileDropping.perform(at: info.location, frames: frames, tabs: tabs))
        }
        guard let target else { return Feedback.dropped(false) }
        return Feedback.dropped(tabs.dropDragged(onto: target.pane, edge: target.edge))
    }

    private func update(_ info: DropInfo) {
        guard tabs.hasDrag else { return }
        let found = DropZone.target(at: info.location, among: frames)
        target = found.flatMap { tabs.canDrop(onto: $0.pane) ? $0 : nil }
    }
}
