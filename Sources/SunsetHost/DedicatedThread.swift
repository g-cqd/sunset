internal import Darwin
internal import Foundation
internal import Synchronization

/// A thread of its own that runs the jobs of the tasks that prefer it (`Task(executorPreference:)`), so that blocking work (waiting for a pseudo-terminal to
/// have output, or to take input) ties up this thread and never one of the cooperative pool. There is no Dispatch: the thread waits on a pipe that
/// enqueuing writes a byte to, and the jobs wait in a list under a mutex.
final class DedicatedThread: TaskExecutor, Sendable {
    private let jobs = Mutex<[UnownedJob]>([])
    private let stopped = Mutex(false)
    private let wakeRead: Int32
    private let wakeWrite: Int32

    private init() {
        var descriptors: [Int32] = [0, 0]
        let created = pipe(&descriptors)
        precondition(created == 0, "pipe failed: \(errno)")
        wakeRead = descriptors[0]
        wakeWrite = descriptors[1]
        _ = fcntl(wakeRead, F_SETFL, O_NONBLOCK)
    }

    deinit {
        close(wakeRead)
        close(wakeWrite)
    }

    /// Starts the thread. It keeps its executor alive until `stop()`.
    static func start() -> DedicatedThread {
        let executor = DedicatedThread()
        Thread.detachNewThread { executor.run() }
        return executor
    }

    func enqueue(_ job: consuming ExecutorJob) {
        let unowned = UnownedJob(job)
        jobs.withLock { $0.append(unowned) }
        wake()
    }

    /// Ends the thread once the jobs already queued have run.
    func stop() {
        stopped.withLock { $0 = true }
        wake()
    }

    private func wake() {
        var byte: UInt8 = 1
        _ = write(wakeWrite, &byte, 1)
    }

    private func run() {
        var scratch = [UInt8](repeating: 0, count: 64)
        let executor = asUnownedTaskExecutor()
        while true {
            var wait = pollfd(fd: wakeRead, events: Int16(POLLIN), revents: 0)
            _ = poll(&wait, 1, -1)
            while read(wakeRead, &scratch, scratch.count) > 0 {}
            let batch = jobs.withLock { list -> [UnownedJob] in
                let taken = list
                list.removeAll()
                return taken
            }
            for job in batch { ExecutorJob(job).runSynchronously(on: executor) }
            if stopped.withLock({ $0 }), jobs.withLock({ $0.isEmpty }) { return }
        }
    }
}
