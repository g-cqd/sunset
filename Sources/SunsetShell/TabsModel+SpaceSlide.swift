import SunsetPane
import SwiftUI

/// The sidebar's list sliding between Spaces (`SpaceSlide`).
extension TabsModel {
    /// A window that only looks at `other`: its list as this window would show it there (what it had selected there, else
    /// the tab a window last went to). It is not registered with the Space: nothing is drawn or claimed through it.
    func preview(of other: SpaceModel) -> TabsModel {
        let selected = selections[other.space.id]?.selected ?? other.lastShown ?? other.tabs.items.first?.id
        return TabsModel(previewing: other, selected: selected, pinned: pinned)
    }

    /// Puts the list `points` from its place (the fingers are on it): the list of the Space on that side is beside it.
    /// Back at its place there is nothing beside. Not while a slide runs.
    package func shift(spaceListTo points: Double) {
        guard !slide.isRunning else { return }
        slide.shift = points
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
            slide.beside = SpaceSlide.Beside(tabs: preview(of: other), isNext: isNext)
        }
    }

    /// Goes to another Space with the list sliding there, the Space being left in sight until the slide ends; at once
    /// when there is no sidebar to slide in. One slide at a time.
    /// - Parameters:
    ///   - other: the Space to show.
    ///   - isNext: it comes from the right (the next one), else from the left.
    package func slide(to other: SpaceModel, isNext: Bool) {
        guard other !== space, !slide.isRunning else { return }
        guard slide.width > 0, let animation = slide.animation, let spaces, spaces.contains(space) else {
            slide.shift = 0
            slide.beside = nil
            return show(space: other)
        }
        if slide.beside?.tabs.space !== other {
            slide.beside = SpaceSlide.Beside(tabs: preview(of: other), isNext: isNext)
        }
        slide.isRunning = true
        let end = isNext ? -slide.width : slide.width
        let arrive: () -> Void = { [weak self] in self?.slide.shift = end }
        let finish: () -> Void = { [weak self] in
            guard let self else { return }
            // In one step with no animation: the other Space's real list takes the place of its picture.
            var plain = Transaction()
            plain.disablesAnimations = true
            withTransaction(plain) {
                self.slide.isRunning = false
                self.slide.shift = 0
                self.slide.beside = nil
                self.show(space: other)
            }
        }
        runSlide(animation, arrive, finish)
    }

    /// The list goes back to its place (the fingers let go before enough was swiped).
    package func settleSpaceList() {
        guard !slide.isRunning, slide.shift != 0, let animation = slide.animation else { return shift(spaceListTo: 0) }
        let back: () -> Void = { [weak self] in self?.slide.shift = 0 }
        let finish: () -> Void = { [weak self] in
            if self?.slide.isRunning == false, self?.slide.shift == 0 { self?.slide.beside = nil }
        }
        runSlide(animation, back, finish)
    }
}
