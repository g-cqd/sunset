/// What the terminal's side says about passwords.
extension TerminalSession {
    /// The program reads a password: echo off in line mode, as `readpassphrase` sets it (an editor or a shell's line editor
    /// turns echo off in raw mode, and is not one). Read from the master side, which shows the PTY's modes (probed
    /// 2026-11-19); a password asked on another host through SSH is not seen (SSH keeps this PTY raw).
    public nonisolated func asksSecret() -> Bool {
        process.asksSecret()
    }
}
