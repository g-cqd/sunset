public import Foundation
import Synchronization

/// A vault in memory, for tests; `failing` makes it one that cannot be used.
public final class MemoryKeyVault: KeyVault {
    private let bytes = Mutex<Data?>(nil)
    private let failing: Bool

    public init(failing: Bool = false) { self.failing = failing }

    public var stored: Data? { bytes.withLock { $0 } }

    public func read() throws(StorageKeyFailure) -> Data? {
        if failing { throw .vault }
        return stored
    }

    public func write(_ bytes: Data) throws(StorageKeyFailure) {
        if failing { throw .vault }
        self.bytes.withLock { $0 = bytes }
    }
}
