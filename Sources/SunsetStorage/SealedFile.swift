public import Foundation
public import SunsetRuntime

/// A file kept sealed and whole (the session): `StoredFile` with a `Seal`.
public enum SealedFile {
    public static func write(
        _ data: Data,
        to path: String,
        seal: Seal,
        identity: String,
        durability: StoredFile.Durability = .ordered
    ) throws(StorageFailure) {
        let sealed: Data
        do {
            sealed = try seal.seal(data, identity: identity)
        } catch {
            throw StorageFailure(step: "seal", code: 0)
        }
        try StoredFile.write(sealed, to: path, durability: durability)
    }

    /// Reads and opens the file, then gives it to `decode`. A file from before sealing (plain) is given as it is, and is sealed
    /// when it is next written. One sealed with another key is `.locked`, left where it is. One that does not open, or that
    /// `decode` does not accept, is moved aside and comes back `.damaged`.
    public static func read<Value>(
        _ path: String,
        as what: String,
        seal: Seal,
        identity: String,
        now: Date = Runtime.live.now(),
        decode: (Data) -> Value?
    ) -> StoredRead<Value> {
        guard let bytes = FileManager.default.contents(atPath: path) else { return .absent }
        let plain: Data?
        do {
            plain = try seal.open(bytes, identity: identity)
        } catch .notSealed {
            plain = bytes
        } catch .otherKey {
            return .locked(StorageProblem(what: what, path: path, movedTo: nil, kind: .locked))
        } catch {
            plain = nil
        }
        if let plain, let value = decode(plain) { return .value(value) }
        return .damaged(StorageProblem(what: what, path: path, movedTo: StoredFile.moveAside(path, now: now)))
    }
}
