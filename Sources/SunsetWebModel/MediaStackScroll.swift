/// A scroll on the Now Playing stack, in cards (roadmap 0114): a card once the fingers went `threshold` points one way,
/// one at a time however fast; what is left over waits for the next. A new gesture starts from nothing.
package struct MediaStackScroll: Equatable, Sendable {
    package let threshold: Double
    private var travelled = 0.0

    package init(threshold: Double) {
        self.threshold = threshold
    }

    /// The cards to move for `delta` more points: -1, 0 or 1.
    package mutating func add(_ delta: Double) -> Int {
        travelled += delta
        guard abs(travelled) >= threshold else { return 0 }
        let cards = travelled > 0 ? 1 : -1
        travelled = 0
        return cards
    }

    package mutating func end() {
        travelled = 0
    }
}
