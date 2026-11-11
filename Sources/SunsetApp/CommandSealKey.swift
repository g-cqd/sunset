import CryptoKit
import Foundation
import Security
import SunsetHost

/// The secret that seals kept terminals' commands (t145), in the login Keychain as a generic password, made on first use. Nil when the Keychain cannot
/// be used: then no command is ever run (they are shown, and saving cannot trust them).
enum CommandSealKey {
    private static let service = "studio.aemi.sunset.command-seal"

    static func load() -> SymmetricKey? {
        if let data = read() { return SymmetricKey(data: data) }
        let key = CommandSeal.newKey()
        let data = key.withUnsafeBytes { Data($0) }
        return write(data) ? key : nil
    }

    private static func read() -> Data? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess, let data = result as? Data,
            data.count == 32
        else { return nil }
        return data
    }

    private static func write(_ data: Data) -> Bool {
        let item: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: "seal",
            kSecAttrLabel: "Sunset: the key that seals the commands of kept terminals", kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        return SecItemAdd(item as CFDictionary, nil) == errSecSuccess
    }
}
