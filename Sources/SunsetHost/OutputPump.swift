internal import Darwin
internal import Synchronization

/// Reads a pseudo-terminal's output on a thread of its own, continuously, into a buffer that the consumer empties in batches.
///
/// The consumer used to pull one read at a time (a task on the reader thread per read, a hop to the consumer, the next read only after the parse): while the
/// output was parsed nobody read, so a program that writes a lot waited in the kernel's small buffer, and every read cost thread switches. Now the reader
/// never waits for the parse, and what arrived meanwhile comes as one batch. It stops reading when `limit` bytes wait (the child is then slowed by the
/// kernel's buffer, as a terminal must), and goes on when the consumer has taken some.
final class OutputPump: Sendable {
    /// One element per change of the buffer (an element still waiting for the consumer is kept, not queued again); finishes when the output has ended.
    let signals: AsyncStream<Void>

    private struct State {
        var pending: [UInt8] = []
        /// The reader is waiting for the consumer to take some.
        var blocked = false
        var wakeups = 0
    }

    private let state = Mutex(State())
    private let continuation: AsyncStream<Void>.Continuation
    private let master: Int32
    private let thread: DedicatedThread
    private let limit: Int
    /// Wake the reader: `stop` and `take` write to these (the reader waits with no timeout).
    private let stopRead: Int32
    private let stopWrite: Int32
    private let resumeRead: Int32
    private let resumeWrite: Int32
    private static let readSize = 128 * 1024

    init(master: Int32, thread: DedicatedThread, limit: Int) {
        (signals, continuation) = AsyncStream.makeStream(of: Void.self, bufferingPolicy: .bufferingNewest(1))
        self.master = master
        self.thread = thread
        self.limit = limit
        (stopRead, stopWrite) = Self.makePipe()
        (resumeRead, resumeWrite) = Self.makePipe()
    }

    deinit {
        for descriptor in [stopRead, stopWrite, resumeRead, resumeWrite] where descriptor >= 0 { close(descriptor) }
    }

    private static func makePipe() -> (Int32, Int32) {
        var ends: [Int32] = [-1, -1]
        guard pipe(&ends) == 0 else { return (-1, -1) }
        for end in ends {
            _ = fcntl(end, F_SETFL, fcntl(end, F_GETFL) | O_NONBLOCK)
            _ = fcntl(end, F_SETFD, FD_CLOEXEC)
        }
        return (ends[0], ends[1])
    }

    /// Starts reading. Call once.
    func start() {
        let pump = self
        Task(executorPreference: thread) { pump.run() }
    }

    /// Ends the reading (the stream finishes).
    func stop() { Self.poke(stopWrite) }

    /// Up to `limit` bytes of what has arrived, in order; empty when nothing waits.
    func take(limit count: Int) -> [UInt8] {
        let (batch, wasBlocked) = state.withLock { state -> ([UInt8], Bool) in
            let taken: [UInt8]
            if state.pending.count <= count {
                taken = state.pending
                state.pending = []
            } else {
                taken = Array(state.pending[0 ..< count])
                state.pending.removeSubrange(0 ..< count)
            }
            let resume = state.blocked && state.pending.count < limit
            if resume { state.blocked = false }
            return (taken, resume)
        }
        if wasBlocked { Self.poke(resumeWrite) }
        return batch
    }

    var pendingBytes: Int { state.withLock { $0.pending.count } }
    var wakeups: Int { state.withLock { $0.wakeups } }

    private static func poke(_ descriptor: Int32) {
        guard descriptor >= 0 else { return }
        var byte: UInt8 = 1
        _ = unsafe write(descriptor, &byte, 1)
    }

    private static func empty(_ descriptor: Int32) {
        var scratch = [UInt8](repeating: 0, count: 16)
        while unsafe read(descriptor, &scratch, scratch.count) > 0 {}
    }

    private func run() {
        defer { continuation.finish() }
        var buffer = [UInt8](repeating: 0, count: Self.readSize)
        while true {
            let isFull = state.withLock { state -> Bool in
                state.wakeups += 1
                let full = state.pending.count >= limit
                if full { state.blocked = true }
                return full
            }
            var waits = [
                pollfd(fd: stopRead, events: Int16(POLLIN), revents: 0),
                pollfd(fd: isFull ? resumeRead : master, events: Int16(POLLIN), revents: 0)
            ]
            let ready = unsafe poll(&waits, 2, -1)
            if ready < 0 {
                if errno == EINTR { continue }
                return
            }
            if waits[0].revents != 0 { return }
            guard waits[1].revents != 0 else { continue }
            if isFull {
                Self.empty(resumeRead)
                continue
            }
            let count = buffer.withUnsafeMutableBytes { raw -> Int in
                unsafe Darwin.read(master, raw.baseAddress, raw.count)
            }
            if count > 0 {
                state.withLock { $0.pending.append(contentsOf: buffer[0 ..< count]) }
                continuation.yield()
            } else if count == 0 || (errno != EINTR && errno != EAGAIN) {
                return
            }
        }
    }
}
