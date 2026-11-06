internal import Darwin
internal import Foundation
internal import Synchronization

/// Tells when a file may have changed: written in place, replaced by an atomic save (an editor writes a temporary file and renames it over the original),
/// created, or deleted. No Dispatch (FSEvents needs a dispatch queue): one kqueue on a thread of its own, watching the file and the directory it is in (or the
/// nearest directory that exists, when the file's own does not yet), and waiting with no timeout while nothing happens.
///
/// A burst of events (an editor writing a file in several steps) is one event: after the first the thread waits until `settle` has passed without another.
public final class FileWatcher: Sendable {
    /// One element for each time the file settled after a change; finishes when the watcher is stopped.
    public let changes: AsyncStream<Void>

    private let continuation: AsyncStream<Void>.Continuation
    private let path: String
    private let settle: Duration
    private let stopWake = WakePipe()
    private let wakeups = Mutex(0)

    public init(path: String, settle: Duration = .milliseconds(100)) {
        self.path = path
        self.settle = settle
        (changes, continuation) = AsyncStream.makeStream(of: Void.self, bufferingPolicy: .bufferingNewest(1))
    }

    deinit { stopWake.close() }

    /// How many times the thread woke up (for a file nobody touches it does not).
    public var wakeupCount: Int { wakeups.withLock { $0 } }

    /// Starts watching on a thread of its own.
    public func start() {
        let watcher = self
        Thread.detachNewThread { watcher.run() }
    }

    public func stop() { stopWake.poke() }

    // MARK: Thread

    private func run() {
        defer { continuation.finish() }
        let queue = kqueue()
        guard queue >= 0 else { return }
        defer { close(queue) }
        arm(queue, descriptor: stopWake.readEnd, filter: Int16(EVFILT_READ), flags: 0)
        var opened = open(forPath: path, queue: queue)
        defer { for descriptor in opened { close(descriptor) } }
        while true {
            wakeups.withLock { $0 += 1 }
            var event = kevent()
            guard unsafe kevent(queue, nil, 0, &event, 1, nil) > 0 else { return }
            if event.filter == Int16(EVFILT_READ) { return }
            // Something changed: wait for the burst to end, then look again and tell once.
            if !settleBurst(queue) { return }
            for descriptor in opened { close(descriptor) }
            opened = open(forPath: path, queue: queue)
            continuation.yield()
        }
    }

    /// Waits until no event has come for `settle`. False when the stop was asked for meanwhile.
    private func settleBurst(_ queue: Int32) -> Bool {
        let seconds = settle.components.seconds
        let nanoseconds = Int(settle.components.attoseconds / 1_000_000_000)
        var timeout = timespec(tv_sec: Int(seconds), tv_nsec: nanoseconds)
        while true {
            var event = kevent()
            let count = unsafe kevent(queue, nil, 0, &event, 1, &timeout)
            if count < 0 { return false }
            if count == 0 { return true }
            if event.filter == Int16(EVFILT_READ) { return false }
        }
    }

    /// Opens the file (if it exists) and its directory, or the nearest directory above that exists, and registers them with the queue.
    private func open(forPath path: String, queue: Int32) -> [Int32] {
        var descriptors: [Int32] = []
        let flags = UInt32(NOTE_WRITE | NOTE_EXTEND | NOTE_DELETE | NOTE_RENAME | NOTE_ATTRIB | NOTE_LINK)
        let file = Darwin.open(path, O_EVTONLY)
        if file >= 0 {
            descriptors.append(file)
            arm(queue, descriptor: file, filter: Int16(EVFILT_VNODE), flags: flags)
        }
        var directory = (path as NSString).deletingLastPathComponent
        while !directory.isEmpty {
            let descriptor = Darwin.open(directory, O_EVTONLY)
            if descriptor >= 0 {
                descriptors.append(descriptor)
                arm(queue, descriptor: descriptor, filter: Int16(EVFILT_VNODE), flags: flags)
                break
            }
            directory = (directory as NSString).deletingLastPathComponent
        }
        return descriptors
    }

    private func arm(_ queue: Int32, descriptor: Int32, filter: Int16, flags: UInt32) {
        var change = kevent(
            ident: UInt(descriptor),
            filter: filter,
            flags: UInt16(EV_ADD | EV_CLEAR),
            fflags: flags,
            data: 0,
            udata: nil
        )
        _ = unsafe kevent(queue, &change, 1, nil, 0, nil)
    }
}
