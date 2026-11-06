internal import Darwin
internal import Synchronization

/// Reads a pseudo-terminal's output on the thread that calls `run`, and hands every read to the caller at once, on that same thread.
///
/// A terminal's output arrives from the kernel in pieces of about a kilobyte (measured: 4 MB in 3154 reads). With a hop to another task for each piece (a
/// wake-up of a pool thread, an actor turn, and back) the hops cost more than the parse itself: 116 000 pieces a second, 70 % of the work of the app was
/// that overhead. Here the thread that reads also parses (the caller locks what it parses into), the way the fast terminals do, so a piece costs two system
/// calls and the parse. While the caller works the reader is not reading, and the child is slowed by the kernel's buffer (the backpressure a terminal must
/// give). It waits on the master and on a pipe that `stop` writes to, with no timeout: an idle terminal does not wake up.
final class OutputPump: Sendable {
    private let master: Int32
    private let stopRead: Int32
    private let stopWrite: Int32
    private let polls = Mutex(0)
    private static let readSize = 128 * 1024

    init(master: Int32) {
        self.master = master
        var ends: [Int32] = [-1, -1]
        if pipe(&ends) == 0 {
            for end in ends {
                _ = fcntl(end, F_SETFL, fcntl(end, F_GETFL) | O_NONBLOCK)
                _ = fcntl(end, F_SETFD, FD_CLOEXEC)
            }
        } else {
            ends = [-1, -1]
        }
        (stopRead, stopWrite) = (ends[0], ends[1])
    }

    deinit {
        if stopRead >= 0 { close(stopRead) }
        if stopWrite >= 0 { close(stopWrite) }
    }

    /// How many times the pump has gone to wait: an idle terminal must not make it wake.
    var wakeups: Int { polls.withLock { $0 } }

    /// Ends `run` (a `stop` before the run began ends it as soon as it starts).
    func stop() {
        guard stopWrite >= 0 else { return }
        var byte: UInt8 = 1
        _ = unsafe write(stopWrite, &byte, 1)
    }

    /// Reads until the output ends or `stop`, calling `body` with each piece, in order. Blocks the calling thread.
    func run(_ body: (UnsafeBufferPointer<UInt8>) -> Void) {
        _ = fcntl(master, F_SETFL, fcntl(master, F_GETFL) | O_NONBLOCK)
        var buffer = [UInt8](repeating: 0, count: Self.readSize)
        while true {
            // Read first: under a flood there is always something, and the wait is a system call saved per piece.
            let count = buffer.withUnsafeMutableBytes { raw -> Int in
                unsafe Darwin.read(master, raw.baseAddress, raw.count)
            }
            if count > 0 {
                buffer.withUnsafeBufferPointer { body(UnsafeBufferPointer(rebasing: $0[0 ..< count])) }
                continue
            }
            if count == 0 { return }
            if errno == EINTR { continue }
            guard errno == EAGAIN else { return }
            polls.withLock { $0 += 1 }
            var waits = [
                pollfd(fd: stopRead, events: Int16(POLLIN), revents: 0),
                pollfd(fd: master, events: Int16(POLLIN), revents: 0)
            ]
            let ready = unsafe poll(&waits, 2, -1)
            if ready < 0, errno != EINTR { return }
            if waits[0].revents != 0 { return }
        }
    }
}
