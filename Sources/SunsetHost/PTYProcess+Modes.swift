import Darwin

/// The PTY's line discipline, read from the master side.
extension PTYProcess {
    /// Echo off in line mode (canonical): how a program reads a password.
    func asksSecret() -> Bool {
        var modes = termios()
        guard unsafe tcgetattr(master, &modes) == 0 else { return false }
        return modes.c_lflag & tcflag_t(ECHO) == 0 && modes.c_lflag & tcflag_t(ICANON) != 0
    }
}
