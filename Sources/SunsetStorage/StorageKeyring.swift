/// Gets the key from where it is kept, makes it the first time, and puts back one from a recovery code (R12, step ST-2).
public struct StorageKeyring: Sendable {
    private let vault: any KeyVault

    public init(vault: any KeyVault = KeychainKeyVault()) {
        self.vault = vault
    }

    /// The key that is kept, without making one.
    public func existing() throws(StorageKeyFailure) -> StorageKey? {
        guard let bytes = try vault.read() else { return nil }
        guard bytes.count == 32 else { throw .vault }
        return StorageKey(bytes: bytes)
    }

    /// The key: the one kept, or a new one, kept from now on.
    public func key() throws(StorageKeyFailure) -> StorageKey {
        if let key = try existing() { return key }
        let key = StorageKey.random()
        try vault.write(key.bytes)
        return key
    }

    /// Keeps the key a recovery code holds. A different key already kept is not replaced unless `replacing`: what it sealed
    /// would no longer open.
    @discardableResult
    public func restore(code: String, replacing: Bool = false) throws(StorageKeyFailure) -> StorageKey {
        let key = try StorageKey(recoveryCode: code)
        if let kept = try existing() {
            if kept.identifier == key.identifier { return kept }
            guard replacing else { throw .keyExists }
        }
        try vault.write(key.bytes)
        return key
    }
}
