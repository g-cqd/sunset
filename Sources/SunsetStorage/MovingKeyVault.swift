public import Foundation

/// The storage key moved from `old` (the login Keychain) to `new` (the data-protection keychain, wrapped by the Secure
/// Enclave: task t121) without a launch that cannot open it:
/// - the first launch copies the key and checks the copy opens to it, and keeps the old;
/// - a later launch that opens the new one, and finds the same key in the old, removes the old;
/// - a new place that cannot be used (a build without the team's entitlement, no Secure Enclave) leaves the key where it
///   was, and it is read from there.
public struct MovingKeyVault: KeyVault {
    let new: any KeyVault
    let old: any KeyVault

    public init(new: any KeyVault, old: any KeyVault) {
        self.new = new
        self.old = old
    }

    public func read() throws(StorageKeyFailure) -> Data? {
        let moved: Data?
        do {
            moved = try new.read()
        } catch {
            return try old.read()
        }
        if let moved {
            let kept: Data?? = try? old.read()
            if kept == .some(moved) { try? old.remove() }
            return moved
        }
        guard let kept = try old.read() else { return nil }
        // Copied and checked; the old stays until a launch has opened the copy.
        do {
            try new.write(kept)
            guard try new.read() == kept else { throw StorageKeyFailure.vault }
        } catch {
            try? new.remove()
        }
        return kept
    }

    public func write(_ bytes: Data) throws(StorageKeyFailure) {
        do {
            try new.write(bytes)
            guard try new.read() == bytes else { throw StorageKeyFailure.vault }
            try? old.remove()
        } catch {
            try? new.remove()
            try old.write(bytes)
        }
    }

    public func remove() throws(StorageKeyFailure) {
        try? new.remove()
        try old.remove()
    }
}
