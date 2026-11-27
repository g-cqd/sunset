package import AppKit
import Foundation

/// Screen-sharing state detection and KVO registration for `WindowLights`.
extension WindowLights {
    static let sharingKey = "hasActiveWindowSharingSession"

    /// True while macOS is sharing this window (`hasActiveWindowSharingSession` or `NSLocalWindowSharingWindow` child).
    package var isSharingWindow: Bool {
        if let sharingOverride { return sharingOverride }
        guard let window else { return false }
        if window.responds(to: NSSelectorFromString(Self.sharingKey)),
            (window.value(forKey: Self.sharingKey) as? Bool) == true
        {
            return true
        }
        return (window.childWindows ?? [])
            .contains {
                NSStringFromClass(type(of: $0)).contains("WindowSharing")
            }
    }

    func observeSharing(of window: NSWindow) {
        guard window.responds(to: NSSelectorFromString(Self.sharingKey)) else { return }
        let relay = SharingRelay { [weak self] in
            MainActor.assumeIsolated {
                self?.place()
                self?.placeLater()
            }
        }
        window.addObserver(relay, forKeyPath: Self.sharingKey, options: [.new], context: nil)
        sharingContextToken = unsafe Unmanaged.passRetained(relay).toOpaque()
    }

    func stopObservingSharing() {
        guard let raw = sharingContextToken else { return }
        sharingContextToken = nil
        let relay = unsafe Unmanaged<SharingRelay>.fromOpaque(raw).takeRetainedValue()
        window?.removeObserver(relay, forKeyPath: Self.sharingKey)
    }

    private final class SharingRelay: NSObject {
        let fire: @Sendable () -> Void

        init(_ fire: @escaping @Sendable () -> Void) {
            self.fire = fire
        }

        // swiftlint:disable:next block_based_kvo - dynamic private key path has no Swift KeyPath literal
        override func observeValue(
            forKeyPath keyPath: String?,
            of object: Any?,
            change: [NSKeyValueChangeKey: Any]?,
            context: UnsafeMutableRawPointer?
        ) {
            fire()
        }
    }
}
