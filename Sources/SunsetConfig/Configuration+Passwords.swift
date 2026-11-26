extension Configuration {
    /// `passwords.*`: when the vault locks besides sleep, the screen locking and quitting (the owner, 2026-11-23), filling
    /// on load (ADR-0094), and automatic `.svault` backup settings (roadmap 0095 B).
    public struct Passwords: Sendable, Equatable {
        /// Minutes without use after which it locks; 0: never by itself.
        public var lockAfter = 10.0
        /// It locks when its tab is left for another of the window.
        public var lockOnLeavingTab = false
        /// It locks when its window is no longer the one in front.
        public var lockOnWindowBlur = false
        /// A sign-in form is filled as its page loads when the site's one login is for the page's very origin (https).
        public var autoFill = false
        /// Folder path for automatic sealed `.svault` backups at quit (empty: off).
        public var backupFolder = ""
        /// How many recent automatic `.svault` backups to keep in `backupFolder`.
        public var backupKeep = 10.0

        public init() {}
    }
}
