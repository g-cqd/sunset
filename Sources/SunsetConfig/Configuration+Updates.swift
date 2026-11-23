extension Configuration {
    /// `updates.*` (roadmap 0122): how Sunset updates itself and its components from its releases.
    public struct Updates: Sendable, Equatable {
        /// Updates are downloaded and checked on their own, and put in place when Sunset quits.
        public var automatic = true
        /// Pre-releases are offered too (every release of Sunset so far is one).
        public var prereleases = true

        public init() {}
    }
}
