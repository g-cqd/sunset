/// A scroll on the Now Playing stack, in cards (roadmap 0114): a card once the fingers went `threshold` points one way, and
/// one card a gesture (n125: the cards snap as pages do, not coast): after it, the rest of the gesture moves nothing. A new
/// gesture starts from nothing.
package struct MediaStackScroll: Equatable, Sendable {
    package let threshold: Double
    private var travelled = 0.0
    private var spent = false

    package init(threshold: Double) {
        self.threshold = threshold
    }

    /// The cards to move for `delta` more points: -1, 0 or 1.
    package mutating func add(_ delta: Double) -> Int {
        guard !spent else { return 0 }
        travelled += delta
        guard abs(travelled) >= threshold else { return 0 }
        spent = true
        return travelled > 0 ? 1 : -1
    }

    package mutating func end() {
        travelled = 0
        spent = false
    }
}
