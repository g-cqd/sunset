import Foundation

/// Watches one key of an object and runs a closure on the main actor when it changes; stops when released.
final class KeyWatch: NSObject {
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

    deinit { object?.removeObserver(self, forKeyPath: key) }

    // swiftlint:disable:next block_based_kvo
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        let changed = changed
        Task { @MainActor in changed() }
    }
}
