internal import SunsetCore
internal import Synchronization

/// What the reader thread and the session share: the terminal behind a lock, and the flag that keeps a flood from announcing itself once per read.
///
/// The reader thread parses straight into `terminal` (see `OutputPump`); the session's other methods (a snapshot for the renderer, keys, a resize) take the
/// same lock for as long as they read or change it, which is short: a read of the pseudo-terminal is a kilobyte or so.
final class SessionCore: Sendable {
    let terminal: Mutex<Terminal>
    /// A `.changed` update has been sent and the consumer has not taken a snapshot since: another one would say nothing new, and under a flood each costs a
    /// wake-up of the consumer.
    let announced = Atomic<Bool>(false)

    init(_ terminal: Terminal) { self.terminal = Mutex(terminal) }

    /// Parses a piece of the program's output; returns what the terminal wants written back and what it asks of the host.
    func ingest(_ bytes: UnsafeBufferPointer<UInt8>) -> (replies: [UInt8], events: [HostEvent]) {
        terminal.withLock { terminal in
            terminal.feed(bytes.span)
            return (terminal.takeReplies(), terminal.takeEvents())
        }
    }
}
