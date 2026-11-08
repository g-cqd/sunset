import SunsetPane
import SwiftUI

/// Receives a tab or a pane dragged over the content of a tab: while it moves, the pane under it and the edge nearest it are worked out (`DropZone`) and
/// published for the overlay; the drop does what the overlay showed. What is dragged is known from the start (`TabsModel.dragged`), so no data is loaded.
struct PaneDropDelegate: DropDelegate {
    let tabs: TabsModel
    let frames: [PaneID: CGRect]
    @Binding var target: DropZone.Target?

    func validateDrop(info: DropInfo) -> Bool { tabs.dragged != nil }

    func dropEntered(info: DropInfo) { update(info) }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        update(info)
        return DropProposal(operation: target == nil ? .cancel : .move)
    }

    func dropExited(info: DropInfo) { target = nil }

    func performDrop(info: DropInfo) -> Bool {
        defer { target = nil }
        guard let target else { return false }
        return tabs.dropDragged(onto: target.pane, edge: target.edge)
    }

    private func update(_ info: DropInfo) {
        let found = DropZone.target(at: info.location, among: frames)
        target = found.flatMap { tabs.canDrop(onto: $0.pane) ? $0 : nil }
    }
}
