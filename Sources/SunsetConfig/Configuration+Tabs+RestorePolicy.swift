extension Configuration.Tabs {
    /// When Sunset brings back saved tabs and terminal scrollback at launch (roadmap 0024 S-3 / t214).
    /// After a crash Sunset always asks regardless of this setting.
    public enum RestorePolicy: String, Sendable, Equatable, CaseIterable {
        case always, ask, never
    }
}
