import SunsetPane
import SwiftUI

/// A Space's icon over which another is dragged (note n14): the dragged one takes its place as soon as it is over it, and the
/// drop ends the drag.
struct SpaceDrop: DropDelegate {
    let target: Space.ID
    @Binding var dragged: Space.ID?
    let spaces: SpacesModel
    let animation: Animation?

    func dropEntered(info: DropInfo) {
        guard let dragged else { return }
        withAnimation(animation) { spaces.drag(dragged, over: target) }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        dragged = nil
        return Feedback.dropped(true)
    }
}
