package import SunsetDocuments

/// The blocks changed both here and on disk, as this pane goes through them (roadmap 0023 step M-e): one is the one it is
/// on, shown in the bar ("1 of 2") and brought into view.
extension DocumentContent {
    /// Where the conflict this pane is on stands among them, from 0: the one last shown while it waits, else the first. Nil
    /// with none.
    package var conflictPlace: Int? {
        let conflicts = document.conflicts
        guard !conflicts.isEmpty else { return nil }
        return conflicts.firstIndex { $0.id == shownConflict } ?? 0
    }

    /// Goes to the next conflict (`step` 1) or the one before (-1), round and round.
    package func showConflict(step: Int) {
        let conflicts = document.conflicts
        guard let place = conflictPlace else { return }
        let next = ((place + step) % conflicts.count + conflicts.count) % conflicts.count
        show(conflict: conflicts[next].id)
    }

    /// Brings the conflict `id` into view.
    package func show(conflict id: Int) {
        shownConflict = id
        reveal += 1
    }

    /// Answers the conflict `id`, and goes to the one that follows it, if any.
    package func answer(_ id: Int, keeping answer: DocumentConflict.Answer) {
        let place = document.conflicts.firstIndex { $0.id == id }
        document.resolve(id, keeping: answer)
        let left = document.conflicts
        guard let place, !left.isEmpty else {
            shownConflict = nil
            return
        }
        show(conflict: left[min(place, left.count - 1)].id)
    }
}
