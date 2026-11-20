import SwiftUI

/// A drop on one target that is lit while what is dragged may land on it (roadmap 0086 E: the Favorites line and a folder's
/// row each had this delegate): `allows` says whether it may, `drop` puts it there and says whether it did.
struct TargetDrop: DropDelegate {
    @Binding var targeted: Bool
    let allows: () -> Bool
    let drop: () -> Bool

    func validateDrop(info: DropInfo) -> Bool {
        allows()
    }

    func dropEntered(info: DropInfo) {
        targeted = allows()
    }

    func dropExited(info: DropInfo) {
        targeted = false
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: targeted ? .move : .cancel)
    }

    func performDrop(info: DropInfo) -> Bool {
        targeted = false
        return Feedback.dropped(drop())
    }
}
