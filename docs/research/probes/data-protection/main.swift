// t121: whether the data-protection keychain and a Secure Enclave wrap work signed as the release is (Developer ID, the
// "Sunset" profile, the team's keychain group), on a probe item of its own (never the storage key) (2026-11-19).
import CryptoKit
import Foundation
import Security

let service = "studio.aemi.sunset.probe-data-protection"
var item: [CFString: Any] = [
    kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: "probe",
    kSecUseDataProtectionKeychain: true
]
SecItemDelete(item as CFDictionary)
var added = item
added[kSecValueData] = Data("probe".utf8)
added[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
let addStatus = SecItemAdd(added as CFDictionary, nil)
var query = item
query[kSecReturnData] = true
var result: CFTypeRef?
let readStatus = SecItemCopyMatching(query as CFDictionary, &result)
print(
    "data-protection add:",
    addStatus,
    "read:",
    readStatus,
    (result as? Data).map { String(decoding: $0, as: UTF8.self) } ?? "-"
)
print("delete:", SecItemDelete(item as CFDictionary))
do {
    guard
        let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            .privateKeyUsage,
            nil
        )
    else { throw CocoaError(.featureUnsupported) }
    let key = try SecureEnclave.MLKEM1024.PrivateKey(accessControl: access)
    let sealed = try key.publicKey.encapsulate()
    print("enclave ML-KEM-1024:", try key.decapsulate(sealed.encapsulated) == sealed.sharedSecret)
} catch { print("enclave:", error) }
