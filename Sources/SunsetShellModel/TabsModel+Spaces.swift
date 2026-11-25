import Foundation
package import SunsetPane

/// A window among the Spaces of the app: it changes to another, and takes tabs there.
extension TabsModel {
    /// This window shows `other` from now on. The Space it leaves runs on, shown by the windows that still show it or by
    /// none; what this window had selected there is remembered for when it comes back. In `other` it shows what it had
    /// selected there, or, the first time, the tab a window last went to.
    /// - Parameters:
    ///   - other: the Space to show.
    ///   - all: the Spaces of the app, when this window is not among them yet.
    package func show(space other: SpaceModel, in all: SpacesModel? = nil) {
        if let all { spaces = all }
        guard other !== space else { return }
        // From a Space of its own (a window that starts, a private one): what it had comes along.
        guard let spaces, spaces.contains(space) else {
            join(other)
            return followProfile()
        }
        if let entry = selectedEntry { left(entry) }
        selections[space.space.id] = SavedView(space: space.space.id, selected: selectedID, entry: selectedEntry)
        let old = space
        selectedID = nil
        selectedEntry = nil
        clearWindowState()
        old.park(self)
        space = other
        other.register(self)
        other.favorites.register(self)
        followProfile()
        revive()
        let back = selections[other.space.id]
        let item = back?.selected ?? other.lastShown ?? other.tabs.items.first?.id
        workspace = workspace.selecting(item, entry: nil)
        if let entry = back?.entry, keeper(of: entry).favorites.entry(entry)?.isOpen == true { select(entry: entry) }
        syncStates()
        onChange()
    }

    /// What is only this window's and names things of the Space it leaves.
    private func clearWindowState() {
        clearMarks()
        bar = nil
        hoveredItem = nil
        hoveredPane = nil
        renaming = nil
        renamingRow = nil
        iconRow = nil
        editingCommand = nil
        unsavedQuestion = nil
    }

    /// The next Space (1) or the one before (-1), round and round.
    package func stepSpace(by offset: Int) {
        guard let spaces, let index = spaces.index(of: space), spaces.spaces.count > 1 else { return }
        let count = spaces.spaces.count
        slide(to: spaces.spaces[((index + offset) % count + count) % count], isNext: offset > 0)
    }

    /// Opens the editor of a new Space. Nothing is made until it is saved.
    package func newSpace() {
        // In the profile of the Space it is made from.
        spaceDraft = spaces?.newDraft()
        spaceDraft?.profile = space.space.profile
    }

    /// Opens the editor of a Space that exists.
    package func edit(space target: SpaceModel) {
        spaceDraft = SpaceDraft(
            space: target.space.id,
            name: target.space.name,
            tint: target.space.tint,
            icon: target.space.icon,
            profile: target.space.profile
        )
    }

    /// Save, in the editor. A new Space is made, with a copy of this one's Favorites, and shown here with the command bar
    /// open (it has no tab); a Space that exists takes what was edited. A draft with no name is not saved.
    package func save(_ draft: SpaceDraft) {
        guard let spaces, draft.canSave else { return }
        spaceDraft = nil
        if let id = draft.space {
            guard let target = spaces.space(id) else { return }
            let before = target.space.profile
            spaces.apply(draft, to: target)
            // Another profile: its pages load again with that profile's website data (Save is the confirmation).
            if target.space.profile != before { target.restart(kind: "web", by: target.currentViewers.first) }
            return
        }
        let made = spaces.add(from: space, as: draft)
        show(space: made)
        if bar == nil { toggleBar() }
    }

    /// Deletes a Space: at once when it holds nothing, else after the question (`deletingSpace`). The last one stays.
    package func deleteSpace(_ target: SpaceModel? = nil) {
        guard let spaces, spaces.spaces.count > 1 else { return }
        let target = target ?? space
        if target.holdsSomething { deletingSpace = target.space.id } else { spaces.remove(target, movingTo: nil) }
    }

    /// The question's answer: what the Space holds goes to its neighbour, or closes.
    package func answerDelete(moving: Bool) {
        guard let spaces, let id = deletingSpace, let target = spaces.space(id) else { return }
        deletingSpace = nil
        spaces.remove(target, movingTo: moving ? spaces.neighbour(of: target) : nil)
    }

    /// The nth Space, from 1; nothing when there is none.
    package func showSpace(number: Int) {
        guard let spaces, spaces.spaces.indices.contains(number - 1) else { return }
        show(spaceInOrder: spaces.spaces[number - 1])
    }

    /// Shows a Space picked by its place (its icon, its key): the list slides in from the side it is on.
    package func show(spaceInOrder other: SpaceModel) {
        guard let spaces, let from = spaces.index(of: space), let to = spaces.index(of: other) else {
            return show(space: other)
        }
        slide(to: other, isNext: to > from)
    }

    /// Whether there is a Space before this window's, and one after: where a swipe can go (it does not go round).
    package func spaceWays(library: SpaceSwipe.LibrarySide?) -> (previous: SpaceSwipe.Way, next: SpaceSwipe.Way) {
        let open = sections.isLibraryOpen
        guard let spaces, let index = spaces.index(of: space) else {
            return SpaceSwipe.ways(index: 0, count: 1, library: library, libraryOpen: open)
        }
        return SpaceSwipe.ways(index: index, count: spaces.spaces.count, library: library, libraryOpen: open)
    }

    /// Moves the tabs among `rows` to another Space, still running, after its own; this window follows them there and
    /// shows the last of them. When `other` belongs to a different profile than `space`, moved non-private web pages
    /// are stopped and reloaded under `other`'s profile so cookies/sessions never leak across profiles. Entries and
    /// folders of the Favorites stay.
    package func move(rows: [RowTarget], to other: SpaceModel) {
        guard other !== space else { return }
        let sourceProfile = space.space.profile
        var items: [Workspace.Item] = []
        var tabs = workspace
        for case .tab(let id) in rows {
            guard let item = tabs.take(item: id) else { continue }
            items.append(item)
        }
        guard !items.isEmpty else { return }
        let extracted = takeContentsAndPending(for: items.flatMap(\.panes))
        workspace = tabs
        other.adopt(items, contents: extracted.contents, pending: extracted.pending)
        show(space: other)
        if sourceProfile != other.space.profile {
            let movedPanes = Set(items.flatMap(\.panes))
            other.restart(kind: PaneDescriptor.webKind, panes: movedPanes, by: self)
        }
        if let last = items.last { select(item: last.id) }
        onChange()
    }

    /// Shows a saved view: its Space among `all` (the first when it is gone), then what it had selected there.
    package func show(_ view: SavedView, in all: SpacesModel) {
        show(space: all.space(view.space) ?? all.spaces[0], in: all)
        show(view)
    }

    // MARK: The command bar

    /// The other Spaces whose name holds what is typed; none for nothing typed, or when the bar picks a tab to split.
    package func barSpaces(_ bar: CommandBar) -> [SpaceModel] {
        let typed = bar.query.trimmingCharacters(in: .whitespaces)
        guard bar.purpose == .search, !typed.isEmpty, let spaces, spaces.spaces.count > 1 else { return [] }
        return spaces.spaces.filter { $0 !== space && $0.space.name.localizedCaseInsensitiveContains(typed) }
    }

    /// The tabs of the other Spaces the bar lists for what is typed, best first in each Space, the Spaces in their order.
    package func barTabsElsewhere(_ bar: CommandBar) -> [(space: SpaceModel, item: Workspace.Item)] {
        let typed = bar.query.trimmingCharacters(in: .whitespaces)
        guard bar.purpose == .search, !typed.isEmpty, let spaces else { return [] }
        return spaces.spaces.filter { $0 !== space }
            .flatMap { other -> [(space: SpaceModel, item: Workspace.Item)] in
                let items = other.tabs.items
                let candidates = items.enumerated()
                    .map { TabSearch.Candidate(id: $0.offset, fields: other.fields(of: $0.element)) }
                return TabSearch.rank(query: bar.query, candidates: candidates).map { (other, items[$0]) }
            }
    }

    /// Goes to a tab of another Space: this window changes to it and shows the tab.
    package func show(_ item: Workspace.ItemID, in other: SpaceModel) {
        bar = nil
        show(spaceInOrder: other)
        select(item: item)
    }
}
