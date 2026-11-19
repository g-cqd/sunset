extension Configuration {
    /// What only the terminal screen has of its own (the window's settings, material and blur, also give the sidebar its look).
    public struct Terminal: Sendable, Equatable {
        /// How opaque the terminal's default background is when the window is not opaque: 1 shows only the terminal's colour, less lets the window's
        /// material show through.
        public var opacity = 0.2
        /// A program may put text on the clipboard (OSC 52); it can never read it (ADR-0010).
        public var clipboardWrite = true
        /// Keys typed in the terminal are kept from other apps' event taps (keyloggers): while a program asks for a password,
        /// always, or never (task t116).
        public var secureKeyboard = SecureKeyboard.whenPassword
        /// A paste that would run commands, or holds control or hidden characters, is asked about first (task t116).
        public var pasteWarning = true
        /// The shell is taught to mark its prompts (OSC 133), which Previous Prompt and Next Prompt go by. zsh is taught (fish does it itself); the user's files are not changed.
        public var shellIntegration = true
        /// Where a new terminal starts when it has no directory of its own (a new tab, a split): a path, `~` for the home folder
        /// (owner, 2026-11-13: an app opened from the Finder runs in `/`, which shells inherited).
        public var directory = "~"
        public init() {}
    }
}
