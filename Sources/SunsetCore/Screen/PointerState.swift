/// The pointer shapes a program asked for on one screen (OSC 22), newest last: the last is the one shown, none means the terminal's own.
struct PointerState: Sendable, Equatable {
    /// kitty keeps 16; pushing past it drops the oldest.
    static let limit = 16

    private(set) var stack: [PointerShape] = []

    var current: PointerShape? { stack.last }

    /// Replaces the shape shown; nil shows the terminal's own again.
    mutating func set(_ shape: PointerShape?) {
        if !stack.isEmpty { stack.removeLast() }
        if let shape { stack.append(shape) }
    }

    mutating func push(_ shape: PointerShape) {
        if stack.count == Self.limit { stack.removeFirst() }
        stack.append(shape)
    }

    mutating func pop() {
        if !stack.isEmpty { stack.removeLast() }
    }
}
