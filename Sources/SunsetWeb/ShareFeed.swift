package import CoreGraphics

/// What Sunset is told by the app about a tab that can be shared (ADR-0082): how to draw a frame of it, whether it is still
/// open, its page's host now.
package struct ShareFeed: Sendable {
    package let frame: @MainActor @Sendable () async -> CGImage?
    package let isOpen: @MainActor @Sendable () -> Bool
    package let host: @MainActor @Sendable () -> String?
    /// The share started (true) or ended (false): the shared tab shows it.
    package let shared: @MainActor @Sendable (Bool) -> Void

    package init(
        frame: @escaping @MainActor @Sendable () async -> CGImage?,
        isOpen: @escaping @MainActor @Sendable () -> Bool,
        host: @escaping @MainActor @Sendable () -> String?,
        shared: @escaping @MainActor @Sendable (Bool) -> Void = { _ in }
    ) {
        self.frame = frame
        self.isOpen = isOpen
        self.host = host
        self.shared = shared
    }
}
