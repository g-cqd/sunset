internal import Darwin

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

/// A child process on a pseudo-terminal: the platform seam of the host (white paper section 9; the core imports none of this). The child runs in its own
/// session with the slave as its controlling terminal; `resize` sets the window size, which the kernel reports to the foreground group as SIGWINCH.
public final class PTYProcess: @unchecked Sendable {
    public let processID: Int32
    private let master: Int32
    private var reaped = false

    private init(master: Int32, processID: pid_t) {
        self.master = master
        self.processID = processID
    }

    /// Runs `command` (executable first) with `environment` added to a minimal default (`TERM=xterm-256color`, `COLORTERM=truecolor`).
    public static func spawn(
        _ command: [String],
        environment: [String: String] = [:],
        columns: Int,
        rows: Int,
        directory: String? = nil
    ) throws -> PTYProcess {
        var master: Int32 = -1
        var slave: Int32 = -1
        var size = winsize(
            ws_row: UInt16(clamping: rows),
            ws_col: UInt16(clamping: columns),
            ws_xpixel: 0,
            ws_ypixel: 0
        )
        guard unsafe openpty(&master, &slave, nil, nil, &size) == 0 else { throw PTYError.openFailed(errno: errno) }
        // The master must not leak into children of children, and reads must not block forever.
        _ = fcntl(master, F_SETFD, FD_CLOEXEC)
        let slaveName = unsafe String(cString: ptsname(master))

        var actions: posix_spawn_file_actions_t?
        unsafe posix_spawn_file_actions_init(&actions)
        defer { unsafe posix_spawn_file_actions_destroy(&actions) }
        // Opening the slave by name after the new session starts makes it the controlling terminal.
        unsafe posix_spawn_file_actions_addopen(&actions, 0, slaveName, O_RDWR, 0)
        unsafe posix_spawn_file_actions_adddup2(&actions, 0, 1)
        unsafe posix_spawn_file_actions_adddup2(&actions, 0, 2)
        if let directory { unsafe posix_spawn_file_actions_addchdir(&actions, directory) }
        var attributes: posix_spawnattr_t?
        unsafe posix_spawnattr_init(&attributes)
        defer { unsafe posix_spawnattr_destroy(&attributes) }
        unsafe posix_spawnattr_setflags(&attributes, Int16(POSIX_SPAWN_SETSID | POSIX_SPAWN_CLOEXEC_DEFAULT))

        var merged = ["TERM": "xterm-256color", "COLORTERM": "truecolor"]
        for (key, value) in environment { merged[key] = value }
        let envp = merged.map { "\($0.key)=\($0.value)" }
        var pid: pid_t = 0
        let status = unsafe withCStrings(command) { argv in
            unsafe withCStrings(envp) { envv in
                unsafe posix_spawnp(&pid, command[0], &actions, &attributes, argv, envv)
            }
        }
        close(slave)
        guard status == 0 else {
            close(master)
            throw PTYError.spawnFailed(errno: status)
        }
        return PTYProcess(master: master, processID: pid)
    }

    deinit {
        close(master)
        if !reaped {
            kill(processID, SIGHUP)
            var status: Int32 = 0
            _ = unsafe waitpid(processID, &status, WNOHANG)
        }
    }

    /// Writes all of `bytes` to the child's input.
    public func write(_ bytes: [UInt8]) throws {
        var offset = 0
        while offset < bytes.count {
            let written = bytes.withUnsafeBytes { raw in
                unsafe Darwin.write(master, raw.baseAddress! + offset, raw.count - offset)
            }
            if written < 0 {
                if errno == EINTR { continue }
                if errno == EAGAIN {
                    var wait = pollfd(fd: master, events: Int16(POLLOUT), revents: 0)
                    _ = unsafe poll(&wait, 1, 100)
                    continue
                }
                throw PTYError.writeFailed(errno: errno)
            }
            offset += written
        }
    }

    /// Waits up to `timeoutMilliseconds` for output and reads what is there into `buffer` (replacing its contents).
    public func read(into buffer: inout [UInt8], timeoutMilliseconds: Int) -> PTYRead {
        var wait = pollfd(fd: master, events: Int16(POLLIN), revents: 0)
        let ready = unsafe poll(&wait, 1, Int32(clamping: timeoutMilliseconds))
        if ready == 0 { return .timeout }
        if ready < 0 { return errno == EINTR ? .timeout : .closed }
        let count = buffer.withUnsafeMutableBytes { raw in
            unsafe Darwin.read(master, raw.baseAddress!, raw.count)
        }
        if count > 0 { return .data(count) }
        if count < 0, errno == EINTR || errno == EAGAIN { return .timeout }
        return .closed
    }

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

    /// The exit status if the child has ended (reaping it), nil while it runs.
    public func exitStatus() -> Int32? {
        guard !reaped else { return 0 }
        var status: Int32 = 0
        let result = unsafe waitpid(processID, &status, WNOHANG)
        guard result == processID else { return nil }
        reaped = true
        // WIFEXITED / WEXITSTATUS / WIFSIGNALED as the macros define them.
        if status & 0x7F == 0 { return (status >> 8) & 0xFF }
        return 128 + (status & 0x7F)
    }
}

/// Calls `body` with a NULL-terminated array of C strings for `strings`, valid during the call.
private func withCStrings<R>(_ strings: [String], _ body: (UnsafePointer<UnsafeMutablePointer<CChar>?>) -> R) -> R {
    var pointers: [UnsafeMutablePointer<CChar>?] = strings.map { unsafe strdup($0) }
    pointers.append(nil)
    defer { for pointer in pointers { unsafe free(pointer) } }
    return pointers.withUnsafeBufferPointer { unsafe body($0.baseAddress!) }
}
