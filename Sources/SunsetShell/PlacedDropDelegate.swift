import SwiftUI

/// What a row or a tile of the sidebar does with something dragged over it (three delegates repeated this whole): where
/// over it the pointer is says what the drop would do (`Place`); the view shows it while it is possible (`active`,
/// `owner` its own), and the drop does it.
@MainActor
struct PlacedDropDelegate<Owner: Equatable, Place>: DropDelegate {
    let owner: Owner
    /// Whether anything dragged now can come here at all.
    let accepts: @MainActor () -> Bool
    /// What a drop at this point would do; nil when it cannot be done here.
    let place: @MainActor (CGPoint) -> Place?
    /// Does it; whether it was taken.
    let drop: @MainActor (Place) -> Bool
    @Binding var active: (owner: Owner, place: Place)?

    func validateDrop(info: DropInfo) -> Bool {
        accepts()
    }

    func dropEntered(info: DropInfo) {
        over(info.location)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        over(info.location)
        return DropProposal(operation: active?.owner == owner ? .move : .cancel)
    }

    func dropExited(info: DropInfo) {
        left()
    }

    func performDrop(info: DropInfo) -> Bool {
        Feedback.dropped(dropped(at: info.location))
    }

    /// The pointer is at `point` over it: its mark says what a drop would do, or it has none.
    func over(_ point: CGPoint) {
        if let place = place(point) {
            if Feedback.sidebarFeel.over("\(owner)|\(place)") { Feedback.snapped() }
            active = (owner, place)
        } else {
            clear()
        }
    }

    /// The pointer left it.
    func left() {
        clear()
    }

    /// A drop at `point`: done when it can be here; the mark goes either way.
    func dropped(at point: CGPoint) -> Bool {
        defer { clear() }
        guard let place = place(point) else {
            return false
        }
        return drop(place)
    }

    private func clear() {
        _ = Feedback.sidebarFeel.over(nil)
        if active?.owner == owner {
            active = nil
        }
    }
}
