extension Configuration.Appearance {
    /// How the ends of lists and titles fade: out, in alpha, or cut.
    public enum Ends: String, Sendable, Equatable, CaseIterable {
        case fade, cut
    }
}
