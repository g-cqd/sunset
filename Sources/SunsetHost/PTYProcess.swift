internal import Darwin
internal import Synchronization

public enum PTYError: Error, Equatable {
    case openFailed(errno: Int32)
    case spawnFailed(errno: Int32)
    case writeFailed(errno: Int32)
}

public enum PTYRead: Equatable {
    case data(Int)
    case timeout
    /// The child closed its side (it exited) and everything it wrote has been read.
    case closed
}

/// A child process on a pseudo-terminal: the platform seam of the host (white paper section 9; the core imports none of this). The child is the leader of a
/// session of its own with the slave as its controlling terminal; `resize` sets the window size, which the kernel reports to the foreground group as
/// SIGWINCH. Reads and writes for concurrent callers (`read()`, `send(_:)`) run on threads of their own, never on the cooperative pool and with no Dispatch.
public final class PTYProcess: Sendable {
    public let processID: Int32
    private let master: Int32
    private let reaped = Mutex(false)
    private let readThread = DedicatedThread.start()
    private let writeThread = DedicatedThread.start()
    private let outbox: AsyncStream<[UInt8]>.Continuation
    private let counters = Counters()

    /// Bytes waiting to be written and sends dropped: shared with the writer task.
    private final class Counters: Sendable {
        let queued = Mutex(0)
        let dropped = Mutex(0)
    }

    /// The most input kept waiting for a child that is not reading it (a paste into a stuck program must not grow memory without bound).
    public static let pendingWriteLimit = 1 << 20

    private init(master: Int32, processID: Int32) {
        self.master = master
        self.processID = processID
        let (stream, continuation) = AsyncStream.makeStream(of: [UInt8].self, bufferingPolicy: .unbounded)
        outbox = continuation
        let fileDescriptor = master
        let counters = counters
        // One writer, in order, on its own thread: a child that is not reading blocks that thread and nothing else.
        Task(executorPreference: writeThread) {
            for await chunk in stream {
                _ = try? PTYProcess.write(chunk, to: fileDescriptor)
                counters.queued.withLock { $0 -= chunk.count }
            }
        }
    }

    /// Runs `command` (executable first) with `environment` added to a minimal default (`TERM=xterm-256color`, `COLORTERM=truecolor`). The child is the leader
    /// of a session of its own with the pseudo-terminal as its controlling terminal (`forkpty`: `posix_spawn` cannot give it one, and a shell that cannot find
    /// its controlling terminal refuses job control: fish says "No TTY for interactive shell"). Everything the child needs is built before the fork; the
    /// child calls nothing but system calls before `execve`.
    public static func spawn(
        _ command: [String],
        environment: [String: String] = [:],
        columns: Int,
        rows: Int,
        directory: String? = nil
    ) throws -> PTYProcess {
        var merged = ["TERM": "xterm-256color", "COLORTERM": "truecolor"]
        for (key, value) in environment { merged[key] = value }
        let envp = merged.map { "\($0.key)=\($0.value)" }
        guard let name = command.first, let program = resolve(name, path: merged["PATH"] ?? "/usr/bin:/bin") else {
            throw PTYError.spawnFailed(errno: ENOENT)
        }
        var size = winsize(
            ws_row: UInt16(clamping: rows),
            ws_col: UInt16(clamping: columns),
            ws_xpixel: 0,
            ws_ypixel: 0
        )
        var master: Int32 = -1
        let pid: Int32 = withCStrings(command) { argv in
            withCStrings(envp) { envv in
                withCStrings([directory ?? ""]) { chdirPath in
                    program.withCString { executable in
                        let child = unsafe forkpty(&master, nil, nil, &size)
                        if child == 0 {
                            execChild(executable, argv, envv, directory: directory == nil ? nil : chdirPath[0])
                        }
                        return child
                    }
                }
            }
        }
        guard pid > 0 else { throw PTYError.openFailed(errno: errno) }
        // The master must not leak into other children.
        _ = fcntl(master, F_SETFD, FD_CLOEXEC)
        return PTYProcess(master: master, processID: pid)
    }

    /// The child after `forkpty`: system calls only, then `execve`.
    private static func execChild(
        _ executable: UnsafePointer<CChar>,
        _ argv: UnsafePointer<UnsafeMutablePointer<CChar>?>,
        _ envv: UnsafePointer<UnsafeMutablePointer<CChar>?>,
        directory: UnsafeMutablePointer<CChar>?
    ) -> Never {
        if let directory { _ = chdir(directory) }
        for number in [SIGPIPE, SIGINT, SIGQUIT, SIGTERM, SIGHUP, SIGCHLD, SIGTSTP, SIGTTIN, SIGTTOU] {
            _ = Darwin.signal(number, SIG_DFL)
        }
        var none = sigset_t()
        sigemptyset(&none)
        _ = unsafe sigprocmask(SIG_SETMASK, &none, nil)
        for descriptor in 3 ..< 256 { close(Int32(descriptor)) }
        unsafe execve(executable, argv, envv)
        _exit(127)
    }

    /// The path of the executable: as given when it has a slash, else the first match along `path`.
    private static func resolve(_ name: String, path: String) -> String? {
        if name.contains("/") { return access(name, X_OK) == 0 ? name : nil }
        for directory in path.split(separator: ":") {
            let candidate = "\(directory)/\(name)"
            if access(candidate, X_OK) == 0 { return candidate }
        }
        return nil
    }

    deinit {
        outbox.finish()
        readThread.stop()
        writeThread.stop()
        close(master)
        if !reaped.withLock({ $0 }) {
            kill(processID, SIGHUP)
            var status: Int32 = 0
            _ = unsafe waitpid(processID, &status, WNOHANG)
        }
    }

    /// The master side of the pseudo-terminal, for a host that waits for output with its own event source (read it only through `read`).
    public var fileDescriptor: Int32 { master }

    // MARK: Output

    /// Waits for output and returns what is there (up to 64 KiB), or nil when the child has closed its side or the awaiting task was cancelled. The wait is
    /// on a thread of its own, so it never ties up the cooperative pool; the reader pulls, so a reader that falls behind makes the child wait in the kernel's
    /// buffer (the backpressure a terminal has to give).
    public func read() async -> [UInt8]? {
        let fileDescriptor = master
        let waiting = Task(executorPreference: readThread) { PTYProcess.blockingRead(fileDescriptor) }
        return await withTaskCancellationHandler {
            await waiting.value
        } onCancel: {
            waiting.cancel()
        }
    }

    private static func blockingRead(_ fileDescriptor: Int32) -> [UInt8]? {
        var buffer = [UInt8](repeating: 0, count: 64 * 1024)
        while !Task.isCancelled {
            switch read(fileDescriptor, into: &buffer, timeoutMilliseconds: 50) {
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

    private static func read(_ fileDescriptor: Int32, into buffer: inout [UInt8], timeoutMilliseconds: Int) -> PTYRead {
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

    private static func write(_ bytes: [UInt8], to fileDescriptor: Int32) throws {
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

    // MARK: Control

    public func resize(columns: Int, rows: Int) {
        var size = winsize(
            ws_row: UInt16(clamping: rows),
            ws_col: UInt16(clamping: columns),
            ws_xpixel: 0,
            ws_ypixel: 0
        )
        _ = unsafe ioctl(master, TIOCSWINSZ, &size)
    }

    public func signal(_ number: Int32) { kill(processID, number) }

    /// Asks the child to end, as closing a terminal window does (SIGHUP).
    public func hangUp() { kill(processID, SIGHUP) }

    /// The exit status, waiting up to `milliseconds` for the child to have ended (blocking: for tools and tests; sessions use `exitStatus(waitingUpTo:)`
    /// from async code).
    public func exitStatusBlocking(waitingUpTo milliseconds: Int) -> Int32? {
        var waited = 0
        while true {
            if let status = exitStatus() { return status }
            if waited >= milliseconds { return nil }
            _ = poll(nil, 0, 5)
            waited += 5
        }
    }

    /// The exit status, waiting up to `milliseconds` on a thread of its own (so the caller's executor is not held).
    public func exitStatus(waitingUpTo milliseconds: Int) async -> Int32? {
        await Task(executorPreference: readThread) { self.exitStatusBlocking(waitingUpTo: milliseconds) }.value
    }

    /// The exit status if the child has ended (reaping it), nil while it runs.
    public func exitStatus() -> Int32? {
        reaped.withLock { done in
            guard !done else { return 0 }
            var status: Int32 = 0
            let result = unsafe waitpid(processID, &status, WNOHANG)
            guard result == processID else { return nil }
            done = true
            // WIFEXITED / WEXITSTATUS / WIFSIGNALED as the macros define them.
            if status & 0x7F == 0 { return (status >> 8) & 0xFF }
            return 128 + (status & 0x7F)
        }
    }
}

/// Calls `body` with a NULL-terminated array of C strings for `strings`, valid during the call.
private func withCStrings<R>(_ strings: [String], _ body: (UnsafePointer<UnsafeMutablePointer<CChar>?>) -> R) -> R {
    var pointers: [UnsafeMutablePointer<CChar>?] = strings.map { unsafe strdup($0) }
    pointers.append(nil)
    defer { for pointer in pointers { unsafe free(pointer) } }
    return pointers.withUnsafeBufferPointer { buffer in
        // A buffer of one NULL at least: the base address is there.
        guard let base = buffer.baseAddress else { fatalError("an array with a terminator has a base address") }
        return unsafe body(base)
    }
}
