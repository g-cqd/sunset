import Foundation
import SunsetCredentials

/// App-Sandboxed, zero-network, zero-file-access XPC service (`studio.aemi.sunset.vault`, N-S5 / R-DES-2).
/// Holds unlocked vault keys exclusively in `SecretBuffer` inside this isolated process and performs `WrappedKey`
/// unwrapping and `Seal(.vaultRecord)` seal/open operations on Sunset's behalf without ever returning raw key bytes.
private final class VaultServiceDelegate: NSObject, NSXPCListenerDelegate, SunsetVaultXPCProtocol {
    private let session = VaultCryptoSession()

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: (any SunsetVaultXPCProtocol).self)
        newConnection.exportedObject = self
        newConnection.resume()
        return true
    }

    func unlockWithFactorKey(
        _ wrappedBlob: NSData,
        factorKey: NSData,
        factor: NSString,
        vaultID: NSString,
        withReply reply: @escaping (Bool) -> Void
    ) {
        guard let uuid = UUID(uuidString: vaultID as String) else {
            reply(false)
            return
        }
        reply(
            session.unlock(
                wrappedBlob: wrappedBlob as Data,
                factorKey: factorKey as Data,
                factor: factor as String,
                vaultID: uuid
            )
        )
    }

    func installKey(_ rawKey: NSData, vaultID: NSString, withReply reply: @escaping (Bool) -> Void) {
        guard let uuid = UUID(uuidString: vaultID as String) else {
            reply(false)
            return
        }
        reply(session.install(rawKey: rawKey as Data, vaultID: uuid))
    }

    func sealRecord(
        _ plain: NSData,
        identity: NSString,
        vaultID: NSString,
        withReply reply: @escaping (NSData?) -> Void
    ) {
        guard let uuid = UUID(uuidString: vaultID as String),
            let sealed = session.seal(plain: plain as Data, identity: identity as String, vaultID: uuid)
        else {
            reply(nil)
            return
        }
        reply(sealed as NSData)
    }

    func openRecord(
        _ sealed: NSData,
        identity: NSString,
        vaultID: NSString,
        withReply reply: @escaping (NSData?) -> Void
    ) {
        guard let uuid = UUID(uuidString: vaultID as String),
            let plain = session.open(sealed: sealed as Data, identity: identity as String, vaultID: uuid)
        else {
            reply(nil)
            return
        }
        reply(plain as NSData)
    }

    func lock(vaultID: NSString, withReply reply: @escaping () -> Void) {
        if let uuid = UUID(uuidString: vaultID as String) {
            session.lock(vaultID: uuid)
        }
        reply()
    }
}

private let vaultDelegate = VaultServiceDelegate()
private let vaultListener = NSXPCListener.service()
vaultListener.delegate = vaultDelegate
vaultListener.resume()
