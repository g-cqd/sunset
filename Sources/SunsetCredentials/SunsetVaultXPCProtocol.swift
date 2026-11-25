public import Foundation

/// Objective-C XPC protocol between Sunset and its App-Sandboxed, zero-network, zero-file-access Vault crypto service
/// (`studio.aemi.sunset.vault`, N-S5 / R-DES-2).
///
/// The raw 256-bit vault key lives exclusively inside the isolated XPC service's `SecretBuffer` while unlocked and is
/// **never** returned to Sunset's main process (which hosts terminal PTYs and web glue). Sunset asks the service only to
/// unwrap factor slots, seal/open individual records bound to `(vaultID, recordID)`, or wipe the key on lock.
@objc public protocol SunsetVaultXPCProtocol {
    func unlockWithFactorKey(
        _ wrappedBlob: NSData,
        factorKey: NSData,
        factor: NSString,
        vaultID: NSString,
        withReply reply: @escaping (Bool) -> Void
    )

    func installKey(_ rawKey: NSData, vaultID: NSString, withReply reply: @escaping (Bool) -> Void)

    func sealRecord(
        _ plain: NSData,
        identity: NSString,
        vaultID: NSString,
        withReply reply: @escaping (NSData?) -> Void
    )

    func openRecord(
        _ sealed: NSData,
        identity: NSString,
        vaultID: NSString,
        withReply reply: @escaping (NSData?) -> Void
    )

    func lock(vaultID: NSString, withReply reply: @escaping () -> Void)
}
