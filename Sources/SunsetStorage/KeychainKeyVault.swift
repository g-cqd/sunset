public import Foundation
import Security

/// The key in the login Keychain, as a generic password (R12, roadmap 0030 step ST-2). On this Mac only: an item that syncs
/// through iCloud Keychain needs an entitlement Sunset does not have (probed 2026-11-14: refused, -34018); syncing is a later
/// decision for the whole app (the owner, the same day), and the recovery code is the net until then.
///
/// `dataProtection`: the data-protection keychain instead (task t121), this Mac only, readable after the first unlock; it
/// needs the team's `keychain-access-groups` (a build without it is refused, -34018, and says `.vault`).
public struct KeychainKeyVault: KeyVault {
    let service: String
    let dataProtection: Bool

    public init(service: String = "studio.aemi.sunset.storage-key", dataProtection: Bool = false) {
        self.service = service
        self.dataProtection = dataProtection
    }

    private var item: [CFString: Any] {
        var item: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: "key"
        ]
        if dataProtection { item[kSecUseDataProtectionKeychain] = true }
        return item
    }

    public func read() throws(StorageKeyFailure) -> Data? {
        var query = item
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = unsafe SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else { throw .vault }
        return data
    }

    public func write(_ bytes: Data) throws(StorageKeyFailure) {
        var added = item
        added[kSecAttrLabel] = "Sunset: the key that seals what Sunset keeps"
        if dataProtection { added[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly }
        added[kSecValueData] = bytes
        var status = SecItemAdd(added as CFDictionary, nil)
        if status == errSecDuplicateItem {
            status = SecItemUpdate(item as CFDictionary, [kSecValueData: bytes] as CFDictionary)
        }
        guard status == errSecSuccess else { throw .vault }
    }

    /// Takes the key out of the Keychain. What it sealed can then be opened only with its recovery code.
    public func remove() throws(StorageKeyFailure) {
        let status = SecItemDelete(item as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw .vault }
    }
}
