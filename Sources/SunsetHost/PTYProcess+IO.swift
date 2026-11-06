internal import Darwin
internal import Synchronization

extension PTYProcess {
    // MARK: Output

    /// Waits for output and returns what is there (up to 64 KiB), or nil when the child has closed its side or the awaiting task was cancelled. The wait is
    /// on a thread of its own, so it never ties up the cooperative pool; the reader pulls, so a reader that falls behind makes the child wait in the kernel's
    /// buffer (the backpressure a terminal has to give).
    public func read() async -> [UInt8]? {
        let (fileDescriptor, wake, counters) = (master, cancelRead, counters)
        let waiting = Task(executorPreference: readThread) {
            PTYProcess.blockingRead(fileDescriptor, wake: wake, counters: counters)
        }
        let cancelWrite = cancelWrite
        return await withTaskCancellationHandler {
            await waiting.value
        } onCancel: {
            waiting.cancel()
            if cancelWrite >= 0 {
                var byte: UInt8 = 1
                _ = unsafe Darwin.write(cancelWrite, &byte, 1)
            }
        }
    }

    /// Waits for output with no timeout, on the master and on the cancellation pipe: an idle terminal does not wake up to look. Without the pipe it looks
    /// every 50 ms.
    static func blockingRead(_ fileDescriptor: Int32, wake: Int32, counters: Counters) -> [UInt8]? {
        var buffer = [UInt8](repeating: 0, count: 64 * 1024)
        var scratch = [UInt8](repeating: 0, count: 16)
        while !Task.isCancelled {
            var waits = [
                pollfd(fd: fileDescriptor, events: Int16(POLLIN), revents: 0),
                pollfd(fd: wake, events: Int16(POLLIN), revents: 0)
            ]
            let ready = unsafe poll(&waits, wake >= 0 ? 2 : 1, wake >= 0 ? -1 : 50)
            counters.readWakeups.withLock { $0 += 1 }
            if ready < 0 {
                if errno == EINTR { continue }
                return nil
            }
            if wake >= 0, waits[1].revents != 0 {
                // A cancellation (maybe one of an earlier read: the loop looks at this task's own flag).
                while unsafe Darwin.read(wake, &scratch, scratch.count) > 0 {}
                continue
            }
            guard waits[0].revents != 0 else { continue }
            switch read(fileDescriptor, into: &buffer, timeoutMilliseconds: 0) {
                case .data(let count): return Array(buffer[0 ..< count])
                case .timeout: continue
                case .closed: return nil
            }
        }
        return nil
    }

    /// Waits up to `timeoutMilliseconds` for output and reads what is there into `buffer` (replacing its contents).
    public func read(into buffer: inout [UInt8], timeoutMilliseconds: Int) -> PTYRead {
        PTYProcess.read(master, into: &buffer, timeoutMilliseconds: timeoutMilliseconds)
    }

    static func read(_ fileDescriptor: Int32, into buffer: inout [UInt8], timeoutMilliseconds: Int) -> PTYRead {
        var wait = pollfd(fd: fileDescriptor, events: Int16(POLLIN), revents: 0)
        let ready = unsafe poll(&wait, 1, Int32(clamping: timeoutMilliseconds))
        if ready == 0 { return .timeout }
        if ready < 0 { return errno == EINTR ? .timeout : .closed }
        let count = buffer.withUnsafeMutableBytes { raw -> Int in
            guard let base = raw.baseAddress else { return -1 }
            return unsafe Darwin.read(fileDescriptor, base, raw.count)
        }
        if count > 0 { return .data(count) }
        if count < 0, errno == EINTR || errno == EAGAIN { return .timeout }
        return .closed
    }

    // MARK: Input

    /// Queues bytes for the child's input and returns at once; they are written in order on a thread of their own, so a child that is not reading cannot
    /// stall the caller. Input beyond `pendingWriteLimit` waiting is dropped (and counted in `droppedSendCount`).
    public func send(_ bytes: [UInt8]) {
        let accepted = counters.queued.withLock { queued -> Bool in
            guard queued + bytes.count <= Self.pendingWriteLimit else { return false }
            queued += bytes.count
            return true
        }
        if accepted { outbox.yield(bytes) } else { counters.dropped.withLock { $0 += 1 } }
    }

    /// How many `send` calls were dropped because the child was not reading.
    public var droppedSendCount: Int { counters.dropped.withLock { $0 } }

    /// Writes all of `bytes` to the child's input, waiting as long as it takes (for a caller that has nothing better to do: tests and tools).
    public func write(_ bytes: [UInt8]) throws { try PTYProcess.write(bytes, to: master) }

    static func write(_ bytes: [UInt8], to fileDescriptor: Int32) throws {
        var offset = 0
        while offset < bytes.count {
            let written = bytes.withUnsafeBytes { raw -> Int in
                guard let base = raw.baseAddress else { return -1 }
                return unsafe Darwin.write(fileDescriptor, base + offset, raw.count - offset)
            }
            if written < 0 {
                if errno == EINTR { continue }
                if errno == EAGAIN {
                    var wait = pollfd(fd: fileDescriptor, events: Int16(POLLOUT), revents: 0)
                    _ = unsafe poll(&wait, 1, 100)
                    continue
                }
                throw PTYError.writeFailed(errno: errno)
            }
            offset += written
        }
    }
}
