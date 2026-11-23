extension Configuration {
    /// `passwords.*`: when the vault locks besides sleep, the screen locking and quitting (the owner, 2026-11-23).
    public struct Passwords: Sendable, Equatable {
        /// Minutes without use after which it locks; 0: never by itself.
        public var lockAfter = 10.0
        /// It locks when its tab is left for another of the window.
        public var lockOnLeavingTab = false
        /// It locks when its window is no longer the one in front.
        public var lockOnWindowBlur = false

        public init() {}
    }
}
