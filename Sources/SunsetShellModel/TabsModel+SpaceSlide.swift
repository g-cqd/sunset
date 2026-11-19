import SunsetPane

/// The sidebar's list sliding between Spaces (`SpaceSlide`).
extension TabsModel {
    /// A window that only looks at `other`: its list as this window would show it there (what it had selected there, else
    /// the tab a window last went to). It is not registered with the Space: nothing is drawn or claimed through it.
    package func preview(of other: SpaceModel) -> TabsModel {
        let selected = selections[other.space.id]?.selected ?? other.lastShown ?? other.tabs.items.first?.id
        let grid = spaces?.profiles.profile(of: other.space).pinned ?? pinned
        return TabsModel(previewing: other, selected: selected, pinned: grid)
    }

    /// What is beside the list while sliding to `other`: its preview, and whether its Pinned grid is this one's.
    package func beside(_ other: SpaceModel, isNext: Bool) -> SpaceSlide.Beside {
        let shown = preview(of: other)
        var beside = SpaceSlide.Beside(tabs: shown, isNext: isNext)
        beside.sharesPinned = shown.pinned === pinned
        beside.sharesFavorites = shown.favorites === favorites
        return beside
    }

    /// Puts the list `points` from its place (the fingers are on it): the list of the Space on that side is beside it.
    /// Back at its place there is nothing beside. Not while a slide runs.
    package func shift(spaceListTo points: Double) {
        guard !slide.isRunning else { return }
        slide.shift = points
        if points != 0 { slide.masks = true }
        guard points != 0, let spaces, let index = spaces.index(of: space) else {
            slide.beside = nil
            return
        }
        let isNext = points < 0
        let neighbour = index + (isNext ? 1 : -1)
        guard spaces.spaces.indices.contains(neighbour) else {
            slide.beside = nil
            return
        }
        let other = spaces.spaces[neighbour]
        if slide.beside?.tabs.space !== other {
            slide.beside = beside(other, isNext: isNext)
        }
    }

    /// Goes to another Space with the list sliding there, the Space being left in sight until the slide ends; at once
    /// when there is no sidebar to slide in. One slide at a time.
    /// - Parameters:
    ///   - other: the Space to show.
    ///   - isNext: it comes from the right (the next one), else from the left.
    package func slide(to other: SpaceModel, isNext: Bool) {
        guard other !== space, !slide.isRunning else { return }
        guard slide.width > 0, let animation = slide.duration, let spaces, spaces.contains(space) else {
            slide.shift = 0
            slide.beside = nil
            return show(space: other)
        }
        if slide.beside?.tabs.space !== other {
            slide.beside = beside(other, isNext: isNext)
        }
        slide.isRunning = true
        let end = isNext ? -slide.width : slide.width
        let arrive: () -> Void = { [weak self] in self?.slide.shift = end }
        let finish: () -> Void = { [weak self] in
            guard let self else { return }
            // In one step with no animation: the other Space's real list takes the place of its picture.
            self.withoutAnimation {
                self.slide.isRunning = false
                self.slide.shift = 0
                self.slide.beside = nil
                self.show(space: other)
            }
            self.unmask()
        }
        slide.masks = true
        runSlide(animation, arrive, finish)
    }

    /// The list goes back to its place (the fingers let go before enough was swiped).
    package func settleSpaceList() {
        guard !slide.isRunning, slide.shift != 0, let animation = slide.duration else { return shift(spaceListTo: 0) }
        let back: () -> Void = { [weak self] in self?.slide.shift = 0 }
        let finish: () -> Void = { [weak self] in
            guard let self, !self.slide.isRunning, self.slide.shift == 0 else { return }
            self.slide.beside = nil
            self.unmask()
        }
        runSlide(animation, back, finish)
    }

    /// The sides' fade goes, in an animation of its own once the list is at rest (roadmap 0045 E).
    private func unmask() {
        guard slide.masks else { return }
        guard let animation = slide.duration else {
            slide.masks = false
            return
        }
        runSlide(animation, { [weak self] in self?.slide.masks = false }, {})
    }
}
