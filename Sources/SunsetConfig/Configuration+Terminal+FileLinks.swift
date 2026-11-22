extension Configuration.Terminal {
    /// What a Cmd-click on a terminal's link to a file of this Mac does (ADR-0118): a program's output can name any file
    /// and label it as anything.
    public enum FileLinks: String, Sendable, Equatable, CaseIterable {
        /// Apps, scripts, executables and installers are shown in the Finder; anything else is opened.
        case revealPrograms
        /// Everything is opened, as the system opens it (an app starts, a script runs).
        case open
        /// Everything is shown in the Finder.
        case reveal

        /// Whether a file that is, or is not, a program is shown in the Finder rather than opened.
        public func reveals(program: Bool) -> Bool {
            switch self {
                case .revealPrograms: program
                case .open: false
                case .reveal: true
            }
        }
    }
}
