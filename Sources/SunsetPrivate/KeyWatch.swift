import Foundation
import SunsetRuntime

/// Watches one key of an object and runs a closure on the main actor when it changes; stops when released.
final class KeyWatch: NSObject {
    /// Where its tasks run, the clock it waits on, the time it reads (ADR-0087); `.live` unless a test sets another.
    var runtime = Runtime.live

    private weak var object: NSObject?
    private let key: String
    private let changed: @MainActor () -> Void

    @MainActor
    init(_ object: NSObject, key: String, changed: @escaping @MainActor () -> Void) {
        self.object = object
        self.key = key
        self.changed = changed
        super.init()
        object.addObserver(self, forKeyPath: key, options: [.new], context: nil)
    }

    deinit {
        object?.removeObserver(self, forKeyPath: key)
    }

    // swiftlint:disable:next block_based_kvo
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        let changed = changed
        runtime.task { @MainActor in changed() }
    }
}
