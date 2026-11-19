extension Configuration.Appearance {
    /// The colour that marks a selection, a focus, a filled control.
    public enum Accent: String, Sendable, Equatable, CaseIterable {
        case system, sunset, neutral
        /// The site shown: its theme colour or its icon's, else the system's (roadmap 0047 H).
        case site
    }
}
