// What an ad hoc signed binary (Sunset's signing today) gets of the Secure Enclave, Touch ID, the keychains and smart cards (2026-11-19).
import CryptoKit
import CryptoTokenKit
import Foundation
import LocalAuthentication
import Security

print("SecureEnclave.isAvailable:", SecureEnclave.isAvailable)
do {
    let key = try SecureEnclave.P256.KeyAgreement.PrivateKey()
    let blob = key.dataRepresentation
    let again = try SecureEnclave.P256.KeyAgreement.PrivateKey(dataRepresentation: blob)
    let peer = P256.KeyAgreement.PrivateKey()
    let a = try key.sharedSecretFromKeyAgreement(with: peer.publicKey)
    let b = try peer.sharedSecretFromKeyAgreement(with: again.publicKey)
    print("SE key made, blob", blob.count, "bytes, restored, agreement equal:", a == b)
} catch { print("SE key:", error) }
do {
    var error: Unmanaged<CFError>?
    guard
        let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            [.privateKeyUsage, .biometryCurrentSet],
            &error
        )
    else { throw CocoaError(.featureUnsupported) }
    _ = try SecureEnclave.P256.KeyAgreement.PrivateKey(accessControl: access)
    print("SE key with biometry access control: made")
} catch { print("SE key with biometry:", error) }
let context = LAContext()
var laError: NSError?
print(
    "biometrics:",
    context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &laError),
    context.biometryType.rawValue,
    laError?.localizedDescription ?? ""
)
print("owner auth (password or watch):", context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil))
func add(_ extra: [String: Any], _ label: String) {
    var query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "sunset-probe-\(label)",
        kSecAttrAccount as String: "probe", kSecValueData as String: Data("x".utf8)
    ]
    query.merge(extra) { $1 }
    let status = SecItemAdd(query as CFDictionary, nil)
    print("keychain \(label):", status, SecCopyErrorMessageString(status, nil) as String? ?? "")
    var delete = query
    delete.removeValue(forKey: kSecValueData as String)
    SecItemDelete(delete as CFDictionary)
}
add([:], "file-based")
add([kSecUseDataProtectionKeychain as String: true], "data-protection")
add([kSecUseDataProtectionKeychain as String: true, kSecAttrSynchronizable as String: true], "iCloud-synchronizable")
if let manager = TKSmartCardSlotManager.default {
    print("smart card slots:", manager.slotNames)
} else {
    print("smart card slot manager: nil (needs com.apple.security.smartcard when sandboxed)")
}
let tokens = TKTokenWatcher().tokenIDs
print("tokens:", tokens)
