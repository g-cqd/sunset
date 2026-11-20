public import AemiTestKit
public import Foundation
public import Testing

/// A key path's values as events (ADR-0087): the value it has when the probe is made, then each new one, recorded as
/// key-value observing announces them. For what AppKit and WebKit say this way (a page loading, its progress, a view's
/// frame), waited for as an `AsyncEventProbe` is: no polling, and no value missed between two looks.
public final class KeyValueProbe<Root: NSObject, Value: Sendable>: Sendable {
    /// Every value seen, in order.
    public let values: AsyncEventProbe<Value>
    /// Kept for as long as the probe; ended with it.
    private let observation: NSKeyValueObservation

    /// Observes `keyPath` of `object`. The handler runs where the change is made: `object` is read there.
    public init(
        _ object: Root,
        _ keyPath: KeyPath<Root, Value>,
        label: String = "",
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let values = AsyncEventProbe<Value>(
            label: label.isEmpty ? "\(Root.self) \(keyPath)" : label,
            sourceLocation: sourceLocation
        )
        self.values = values
        observation = object.observe(keyPath, options: [.initial]) { object, _ in
            values.record(object[keyPath: keyPath])
        }
    }

    deinit {
        observation.invalidate()
    }

    /// Waits until some value since the probe was made satisfies `condition` (each is looked at, in order); that value.
    @discardableResult
    public func wait<C: Clock>(
        until condition: @escaping @Sendable (Value) -> Bool,
        within limit: C.Duration,
        clock: C
    ) async throws -> Value {
        let seen = try await values.wait(until: { $0.last.map(condition) ?? false }, within: limit, clock: clock)
        guard let last = seen.last else { preconditionFailure("a wait that ended has seen a value") }
        return last
    }

    /// On the wall clock, for at most `limit`: a hang guard, not a latency assertion.
    @discardableResult
    public func wait(until condition: @escaping @Sendable (Value) -> Bool, within limit: Duration = .seconds(30))
        async throws -> Value
    {
        try await wait(until: condition, within: limit, clock: ContinuousClock())
    }

    /// Waits until the values seen so far, in order, satisfy `condition` (a change from one value to another: loading,
    /// then not); all of them.
    @discardableResult
    public func wait(history condition: @escaping @Sendable ([Value]) -> Bool, within limit: Duration = .seconds(30))
        async throws -> [Value]
    {
        try await values.wait(until: condition, within: limit, clock: ContinuousClock())
    }
}
