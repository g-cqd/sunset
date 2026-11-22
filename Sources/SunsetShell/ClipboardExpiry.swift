package import AppKit
package import SunsetRuntime

/// A secret copied leaves the clipboard on its own after `delay`, as password managers do, unless something else was
/// copied since (the pasteboard's change count moved): what the person copied since stays. One secret at a time: a new
/// one starts the delay again. On the runtime's clock.
@MainActor
package final class ClipboardExpiry {
    /// A minute and a half: time to paste, not to leave a password lying about.
    package static let shared = ClipboardExpiry(after: .seconds(90), runtime: .live)

    private let delay: Duration
    private let runtime: Runtime
    private var pending: Task<Void, Never>?

    package init(after delay: Duration, runtime: Runtime) {
        self.delay = delay
        self.runtime = runtime
    }

    /// A secret was just put on `board`: cleared after the delay, if it is still what is there.
    package func secretCopied(to board: NSPasteboard) {
        pending?.cancel()
        let count = board.changeCount
        pending = runtime.task { @MainActor [delay, runtime] in
            guard await runtime.sleep(for: delay), board.changeCount == count else { return }
            board.clearContents()
        }
    }
}
