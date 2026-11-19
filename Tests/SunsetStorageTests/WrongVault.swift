import Foundation

@testable import SunsetStorage

/// Keeps something else than it is given.
final class WrongVault: KeyVault {
    let inner = MemoryKeyVault()

    func read() throws(StorageKeyFailure) -> Data? {
        try inner.read()
    }

    func write(_ bytes: Data) throws(StorageKeyFailure) {
        try inner.write(Data(bytes.reversed()))
    }

    func remove() throws(StorageKeyFailure) {
        try inner.remove()
    }
}
