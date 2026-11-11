public import SunsetCore

/// What the settings let a program ask of the host (ADR-0010), before the host does it.
public struct HostPolicy: Sendable, Equatable {
    /// `terminal.clipboardWrite`: OSC 52 puts text on the clipboard.
    public var clipboardWrite: Bool

    public init(clipboardWrite: Bool = true) {
        self.clipboardWrite = clipboardWrite
    }

    public func admits(_ event: HostEvent) -> Bool {
        switch event {
            case .clipboardWrite: clipboardWrite
            case .notification: true
        }
    }
}
