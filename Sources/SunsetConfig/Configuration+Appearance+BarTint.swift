extension Configuration.Appearance {
    /// `appearance.barTint`: the fill inside the bars' glass, and their controls' scheme.
    public enum BarTint: String, Sendable, Equatable, CaseIterable {
        case scheme, dark, light
    }
}
