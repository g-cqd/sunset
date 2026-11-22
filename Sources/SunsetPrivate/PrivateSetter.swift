internal import Foundation

/// A setter of WebKit's that is not public, called by its name with a plain value (not an object: `perform(_:with:)`
/// would pass a pointer). Nothing is called when the object does not answer to it.
@MainActor
enum PrivateSetter {
    /// Calls `object`'s `name` with `value`; false when it has no such method.
    @discardableResult
    static func set(_ name: String, to value: UInt, on object: NSObject) -> Bool {
        guard let (selector, method) = method(name, of: object) else { return false }
        typealias Setter = @convention(c) (NSObject, Selector, UInt) -> Void
        unsafe unsafeBitCast(method, to: Setter.self)(object, selector, value)
        return true
    }

    /// Calls `object`'s `name` with `value`; false when it has no such method.
    @discardableResult
    static func set(_ name: String, to value: Bool, on object: NSObject) -> Bool {
        guard let (selector, method) = method(name, of: object) else { return false }
        typealias Setter = @convention(c) (NSObject, Selector, Bool) -> Void
        unsafe unsafeBitCast(method, to: Setter.self)(object, selector, value)
        return true
    }

    private static func method(_ name: String, of object: NSObject) -> (Selector, IMP)? {
        let selector = NSSelectorFromString(name)
        guard object.responds(to: selector) else { return nil }
        return (selector, object.method(for: selector))
    }
}
