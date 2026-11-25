import Dispatch
public import Foundation
import SunsetStorage
import Synchronization

/// Objective-C XPC protocol between Sunset and its App-Sandboxed, zero-network, zero-file-access Vault crypto service
/// (`studio.aemi.sunset.vault`, N-S5 / R-DES-2).
///
/// The raw 256-bit vault key lives exclusively inside the isolated XPC service's `SecretBuffer` while unlocked and is
/// **never** returned to Sunset's main process (which hosts terminal PTYs and web glue). Sunset asks the service only to
/// unwrap factor slots, seal/open individual records bound to `(vaultID, recordID)`, or wipe the key on lock.
@objc public protocol SunsetVaultXPCProtocol {
    /// Unwraps `wrappedBlob` with `factorKey` for `factor` and `vaultID`, storing the raw vault key strictly inside the
    /// XPC service's `SecretBuffer`. Never returns the raw key.
    func unlockWithFactorKey(
        _ wrappedBlob: NSData,
        factorKey: NSData,
        factor: NSString,
        vaultID: NSString,
        withReply reply: @escaping (Bool) -> Void
    )

    /// Stores a freshly created vault key inside the XPC service for `vaultID` (used once at `Vault.create`).
    func installKey(_ rawKey: NSData, vaultID: NSString, withReply reply: @escaping (Bool) -> Void)

    /// Seals `plain` for `identity` under the held vault key for `vaultID`.
    func sealRecord(
        _ plain: NSData,
        identity: NSString,
        vaultID: NSString,
        withReply reply: @escaping (NSData?) -> Void
    )

    /// Opens `sealed` for `identity` under the held vault key for `vaultID`.
    func openRecord(
        _ sealed: NSData,
        identity: NSString,
        vaultID: NSString,
        withReply reply: @escaping (NSData?) -> Void
    )

    /// Zeroes and drops the held vault key for `vaultID`.
    func lock(vaultID: NSString, withReply reply: @escaping () -> Void)
}

/// Pure, testable in-process core of `SunsetVaultService.xpc`: holds unlocked vault keys in `SecretBuffer`s keyed by
/// vault UUID and performs `WrappedKey.unwrap` + `Seal(.vaultRecord)` seal/open without ever exporting raw key bytes.
public final class VaultCryptoSession: @unchecked Sendable {
    private let lockObject = NSLock()
    private var keys: [UUID: SecretBuffer] = [:]

    public init() {}

    /// Unwraps `wrappedBlob` with `factorKey` and retains the resulting vault key inside `SecretBuffer`.
    public func unlock(wrappedBlob: Data, factorKey: Data, factor: String, vaultID: UUID) -> Bool {
        guard let wrapped = try? JSONDecoder().decode(WrappedKey.self, from: wrappedBlob),
            let key = try? wrapped.unwrap(with: factorKey, vault: vaultID)
        else { return false }
        let buffer = SecretBuffer(key.bytes)
        lockObject.lock()
        defer { lockObject.unlock() }
        keys[vaultID]?.wipe()
        keys[vaultID] = buffer
        return true
    }

    /// Retains a freshly created 32-byte key inside `SecretBuffer` for `vaultID`.
    public func install(rawKey: Data, vaultID: UUID) -> Bool {
        guard rawKey.count == 32 else { return false }
        let buffer = SecretBuffer(rawKey)
        lockObject.lock()
        defer { lockObject.unlock() }
        keys[vaultID]?.wipe()
        keys[vaultID] = buffer
        return true
    }

    /// Seals `plain` under `Seal(.vaultRecord)` for `identity` using the held key for `vaultID`.
    public func seal(plain: Data, identity: String, vaultID: UUID) -> Data? {
        withVaultSeal(vaultID: vaultID) { try? $0.seal(plain, identity: identity) }
    }

    /// Opens `sealed` under `Seal(.vaultRecord)` for `identity` using the held key for `vaultID`.
    public func open(sealed: Data, identity: String, vaultID: UUID) -> Data? {
        withVaultSeal(vaultID: vaultID) { try? $0.open(sealed, identity: identity) }
    }

    private func withVaultSeal(vaultID: UUID, _ body: (Seal) -> Data?) -> Data? {
        lockObject.lock()
        defer { lockObject.unlock() }
        guard let buffer = keys[vaultID] else { return nil }
        var output: Data?
        buffer.withBytes { bytes in
            output = body(Seal(key: StorageKey(bytes: Data(bytes)), purpose: .vaultRecord))
        }
        return output
    }

    /// Zeroes and drops the held key for `vaultID`.
    public func lock(vaultID: UUID) {
        lockObject.lock()
        defer { lockObject.unlock() }
        if let buffer = keys.removeValue(forKey: vaultID) {
            buffer.wipe()
        }
    }

    /// Whether a key is currently held for `vaultID`.
    public func isUnlocked(vaultID: UUID) -> Bool {
        lockObject.lock()
        defer { lockObject.unlock() }
        return keys[vaultID] != nil
    }
}

/// Client proxy talking to the embedded App-Sandboxed `SunsetVaultService.xpc` (`studio.aemi.sunset.vault` /
/// `studio.aemi.sunset.dev.vault`) when bundled inside `Sunset.app`.
public final class VaultXPCClient: Sendable {
    public static let timeoutSeconds: TimeInterval = 5.0

    private let serviceName: String
    private let connectionLock = Mutex<NSXPCConnection?>(nil)

    public init(serviceName: String) {
        self.serviceName = serviceName
    }

    /// Resolves the embedded vault XPC service name if `Bundle.main` ships `Contents/XPCServices/SunsetVaultService.xpc`.
    public static func bundledServiceName(in bundle: Bundle = .main) -> String? {
        let relative = "Contents/XPCServices/SunsetVaultService.xpc"
        guard let id = bundle.bundleIdentifier,
            FileManager.default.fileExists(atPath: bundle.bundleURL.appending(path: relative).path)
        else { return nil }
        return "\(id).vault"
    }

    private func activeConnection() -> NSXPCConnection {
        connectionLock.withLock { existing in
            if let existing { return existing }
            let conn = NSXPCConnection(serviceName: serviceName)
            conn.remoteObjectInterface = NSXPCInterface(with: (any SunsetVaultXPCProtocol).self)
            conn.resume()
            existing = conn
            return conn
        }
    }

    public func unlock(wrapped: WrappedKey, factorKey: Data, factor: String, vaultID: UUID) -> Bool {
        guard let blob = try? JSONEncoder().encode(wrapped) else { return false }
        return callBool { proxy, done in
            proxy.unlockWithFactorKey(
                blob as NSData,
                factorKey: factorKey as NSData,
                factor: factor as NSString,
                vaultID: vaultID.uuidString as NSString,
                withReply: done
            )
        }
    }

    public func install(rawKey: Data, vaultID: UUID) -> Bool {
        callBool { proxy, done in
            proxy.installKey(rawKey as NSData, vaultID: vaultID.uuidString as NSString, withReply: done)
        }
    }

    public func seal(plain: Data, identity: String, vaultID: UUID) -> Data? {
        callData { proxy, done in
            proxy.sealRecord(
                plain as NSData,
                identity: identity as NSString,
                vaultID: vaultID.uuidString as NSString,
                withReply: done
            )
        }
    }

    public func open(sealed: Data, identity: String, vaultID: UUID) -> Data? {
        callData { proxy, done in
            proxy.openRecord(
                sealed as NSData,
                identity: identity as NSString,
                vaultID: vaultID.uuidString as NSString,
                withReply: done
            )
        }
    }

    public func lock(vaultID: UUID) {
        let sem = DispatchSemaphore(value: 0)
        let proxy =
            activeConnection().remoteObjectProxyWithErrorHandler { _ in sem.signal() } as? any SunsetVaultXPCProtocol
        guard let proxy else { return }
        proxy.lock(vaultID: vaultID.uuidString as NSString) { sem.signal() }
        _ = sem.wait(timeout: .now() + Self.timeoutSeconds)
    }

    private func callBool(_ body: (any SunsetVaultXPCProtocol, @escaping (Bool) -> Void) -> Void) -> Bool {
        let sem = DispatchSemaphore(value: 0)
        let box = Mutex(false)
        let proxy =
            activeConnection().remoteObjectProxyWithErrorHandler { _ in sem.signal() } as? any SunsetVaultXPCProtocol
        guard let proxy else { return false }
        body(proxy) { ok in
            box.withLock { $0 = ok }
            sem.signal()
        }
        _ = sem.wait(timeout: .now() + Self.timeoutSeconds)
        return box.withLock { $0 }
    }

    private func callData(_ body: (any SunsetVaultXPCProtocol, @escaping (NSData?) -> Void) -> Void) -> Data? {
        let sem = DispatchSemaphore(value: 0)
        let box = Mutex<Data?>(nil)
        let proxy =
            activeConnection().remoteObjectProxyWithErrorHandler { _ in sem.signal() } as? any SunsetVaultXPCProtocol
        guard let proxy else { return nil }
        body(proxy) { data in
            box.withLock { $0 = data as Data? }
            sem.signal()
        }
        _ = sem.wait(timeout: .now() + Self.timeoutSeconds)
        return box.withLock { $0 }
    }
}
