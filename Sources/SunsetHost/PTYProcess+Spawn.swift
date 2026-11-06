internal import Darwin

extension PTYProcess {
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
    static func execChild(
        _ executable: UnsafePointer<CChar>,
        _ argv: UnsafePointer<UnsafeMutablePointer<CChar>?>,
        _ envv: UnsafePointer<UnsafeMutablePointer<CChar>?>,
        directory: UnsafeMutablePointer<CChar>?
    ) -> Never {
        if let directory { _ = chdir(directory) }
        // No allocation and no runtime calls here: this is the child of a multi-threaded process, and a lock another thread held at the fork (the allocator's) is
        // never released in the child. A range loop and an array literal in an unoptimised build are runtime calls that can allocate.
        var number: Int32 = 1
        while number < 32 {
            // SIGKILL and SIGSTOP cannot be changed (the call fails, harmlessly).
            _ = Darwin.signal(number, SIG_DFL)
            number += 1
        }
        var none = sigset_t()
        sigemptyset(&none)
        _ = unsafe sigprocmask(SIG_SETMASK, &none, nil)
        var descriptor: Int32 = 3
        while descriptor < 256 {
            close(descriptor)
            descriptor += 1
        }
        unsafe execve(executable, argv, envv)
        _exit(127)
    }

    /// The path of the executable: as given when it has a slash, else the first match along `path`.
    static func resolve(_ name: String, path: String) -> String? {
        if name.contains("/") { return access(name, X_OK) == 0 ? name : nil }
        for directory in path.split(separator: ":") {
            let candidate = "\(directory)/\(name)"
            if access(candidate, X_OK) == 0 { return candidate }
        }
        return nil
    }
}
