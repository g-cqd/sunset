public import Foundation
import Synchronization

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
        return call(default: false) { proxy, done in
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
        call(default: false) { proxy, done in
            proxy.installKey(rawKey as NSData, vaultID: vaultID.uuidString as NSString, withReply: done)
        }
    }

    public func seal(plain: Data, identity: String, vaultID: UUID) -> Data? {
        call(default: nil) { proxy, done in
            proxy.sealRecord(
                plain as NSData,
                identity: identity as NSString,
                vaultID: vaultID.uuidString as NSString
            ) { done($0 as Data?) }
        }
    }

    public func open(sealed: Data, identity: String, vaultID: UUID) -> Data? {
        call(default: nil) { proxy, done in
            proxy.openRecord(
                sealed as NSData,
                identity: identity as NSString,
                vaultID: vaultID.uuidString as NSString
            ) { done($0 as Data?) }
        }
    }

    public func lock(vaultID: UUID) {
        call(default: ()) { proxy, done in
            proxy.lock(vaultID: vaultID.uuidString as NSString) { done(()) }
        }
    }

    private func call<Value: Sendable>(
        default fallback: Value,
        _ invoke: (any SunsetVaultXPCProtocol, @escaping @Sendable (Value) -> Void) -> Void
    ) -> Value {
        let gate = Waiter<Value>(fallback)
        let proxy =
            activeConnection()
            .remoteObjectProxyWithErrorHandler { _ in
                gate.signal(fallback)
            } as? any SunsetVaultXPCProtocol
        guard let proxy else { return fallback }
        invoke(proxy) { gate.signal($0) }
        return gate.wait(seconds: Self.timeoutSeconds)
    }

    private final class Waiter<Value: Sendable>: @unchecked Sendable {
        private let condition = NSCondition()
        private var done = false
        private var value: Value

        init(_ initial: Value) {
            value = initial
        }

        func signal(_ newValue: Value) {
            condition.lock()
            if !done {
                value = newValue
                done = true
                condition.signal()
            }
            condition.unlock()
        }

        func wait(seconds: TimeInterval) -> Value {
            let deadline = Date(timeIntervalSinceNow: seconds)
            condition.lock()
            while !done, condition.wait(until: deadline) {}
            let result = value
            condition.unlock()
            return result
        }
    }
}
