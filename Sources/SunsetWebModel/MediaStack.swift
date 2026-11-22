/// The Now Playing stack at the foot of the sidebar (roadmap 0114): a card for each page whose media played, the latest
/// to start first; one in front, the tops of at most two more behind it. A paused page keeps its card, to be played
/// again; a page that never played has none. The page goes, its card goes.
package struct MediaStack: Equatable, Sendable {
    /// How many cards are drawn: the front one and the tops of those behind it.
    package static let drawn = 3

    package private(set) var pages: [MediaPage] = []
    /// The index of the card in front.
    private var top = 0

    package init() {}

    package var front: MediaPage? {
        pages.indices.contains(top) ? pages[top] : nil
    }

    /// The front card, then those behind it, at most `drawn`.
    package var shown: [MediaPage] {
        Array(pages.dropFirst(top).prefix(Self.drawn))
    }

    /// A page as it is now. One that starts playing comes first and in front; one that plays on, or pauses, keeps its
    /// place.
    package mutating func update(_ page: MediaPage) {
        guard let index = pages.firstIndex(where: { $0.id == page.id }) else {
            guard page.isPlaying else { return }
            pages.insert(page, at: 0)
            top = 0
            return
        }
        let starts = page.isPlaying && !pages[index].isPlaying
        guard starts else {
            pages[index] = page
            return
        }
        pages.remove(at: index)
        pages.insert(page, at: 0)
        top = 0
    }

    /// The page went (closed, or its media with it): its card goes; the front stays on the card it showed.
    package mutating func remove(_ id: MediaPage.ID) {
        guard let index = pages.firstIndex(where: { $0.id == id }) else { return }
        pages.remove(at: index)
        if index < top { top -= 1 }
        top = min(top, max(pages.count - 1, 0))
    }

    /// Brings the card `cards` further back (negative: nearer) to the front, within the stack.
    package mutating func scroll(_ cards: Int) {
        top = min(max(top + cards, 0), max(pages.count - 1, 0))
    }
}
